import Foundation

public struct AppUninstallBundle: Sendable {
    public let appName: String
    public let bundleId: String?
    public let appURL: URL
    public let associatedItems: [CleanItem]
    
    public var totalSizeBytes: Int64 {
        return associatedItems.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var formattedTotalSize: String {
        return ByteFormatter.format(totalSizeBytes)
    }
}

public final class AppUninstaller: Sendable {
    public static let shared = AppUninstaller()

    public init() {}

    /// Analyze an application bundle URL and find all associated leftovers across macOS
    public func analyzeApp(at appURL: URL) -> AppUninstallBundle? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: appURL.path) else { return nil }

        let bundle = Bundle(url: appURL)
        let appName = appURL.deletingPathExtension().lastPathComponent
        let bundleId = bundle?.bundleIdentifier

        var items: [CleanItem] = []
        let whitelist = WhitelistManager.shared

        // 1. Add the .app itself
        let appSize = FileUtils.calculateSize(atPath: appURL.path)
        items.append(CleanItem(
            name: "\(appName).app 主程序包",
            path: appURL.path,
            sizeBytes: appSize,
            category: .orphanLeftovers,
            safetyLevel: .safe,
            itemDescription: "应用程序的核心执行二进制文件与资源包",
            associatedAppName: appName
        ))

        // Extract Info.plist extra tokens
        var searchTokens = Set<String>()
        searchTokens.insert(appName.lowercased())
        if let infoDict = bundle?.infoDictionary {
            if let cfName = infoDict["CFBundleName"] as? String {
                searchTokens.insert(cfName.lowercased())
            }
            if let dispName = infoDict["CFBundleDisplayName"] as? String {
                searchTokens.insert(dispName.lowercased())
            }
            if let execName = infoDict["CFBundleExecutable"] as? String {
                searchTokens.insert(execName.lowercased())
            }
        }

        if let bId = bundleId?.lowercased() {
            searchTokens.insert(bId)
            let subTokens = bId.split(separator: ".")
            if let last = subTokens.last {
                searchTokens.insert(String(last))
            }
        }

        // Directories to inspect for app-specific leftovers (User & System-wide)
        let candidateDirectories: [(dir: String, cat: String, safety: SafetyLevel)] = [
            ("~/Library/Application Support", "配置与核心数据", .caution),
            ("~/Library/Caches", "运行缓存", .safe),
            ("~/Library/Containers", "沙盒隔离容器", .caution),
            ("~/Library/Group Containers", "共享数据组", .caution),
            ("~/Library/Preferences", "偏好设置文件", .caution),
            ("~/Library/Saved Application State", "退出窗口镜像", .safe),
            ("~/Library/WebKit", "内置网页缓存", .safe),
            ("~/Library/HTTPStorages", "网络缓存", .safe),
            ("~/Library/Logs", "运行日志", .safe),
            ("~/Library/LaunchAgents", "自启守护脚本", .safe),
            ("/Library/Application Support", "系统级配置与数据", .caution),
            ("/Library/Caches", "系统级运行缓存", .safe),
            ("/Library/Preferences", "系统级偏好设置", .caution),
            ("/Library/LaunchAgents", "全局启动服务", .safe),
            ("/Library/LaunchDaemons", "系统级守护脚本", .safe)
        ]

        for candidate in candidateDirectories {
            let expandedDir = FileUtils.expandPath(candidate.dir)
            guard let subItems = try? fileManager.contentsOfDirectory(atPath: expandedDir) else {
                continue
            }

            for sub in subItems {
                let subLower = sub.lowercased()
                var isMatch = false

                // Check exact bundleId match
                if let bId = bundleId?.lowercased(), subLower.contains(bId) {
                    isMatch = true
                } else {
                    // Check if token matches
                    for token in searchTokens {
                        if token == appName.lowercased() {
                            if subLower == token || subLower.hasPrefix("\(token).") || subLower.hasSuffix(".\(token)") {
                                isMatch = true
                                break
                            }
                        } else if token.count >= 3 {
                            if subLower == token || subLower.hasPrefix("\(token).") || subLower.hasSuffix(".\(token)") || subLower.contains(".\(token).") {
                                isMatch = true
                                break
                            }
                        }
                    }
                }

                let fullPath = (expandedDir as NSString).appendingPathComponent(sub)

                // Extra check for LaunchAgents / LaunchDaemons plist content targeting this app
                if !isMatch && (candidate.dir.contains("LaunchAgents") || candidate.dir.contains("LaunchDaemons")) && sub.hasSuffix(".plist") {
                    if isPlistTargetingApp(plistPath: fullPath, appPath: appURL.path, bundleId: bundleId) {
                        isMatch = true
                    }
                }

                if isMatch {
                    if whitelist.isProtected(path: fullPath, mode: .strict) || fullPath == appURL.path {
                        continue
                    }

                    let size = FileUtils.calculateSize(atPath: fullPath)
                    items.append(CleanItem(
                        name: "\(sub) [\(candidate.cat)]",
                        path: fullPath,
                        sizeBytes: max(size, 4096),
                        category: .orphanLeftovers,
                        safetyLevel: candidate.safety,
                        itemDescription: "\(appName) 关联的 \(candidate.cat)",
                        associatedAppName: appName,
                        isSelected: candidate.safety == .safe
                    ))
                }
            }
        }

        return AppUninstallBundle(
            appName: appName,
            bundleId: bundleId,
            appURL: appURL,
            associatedItems: items
        )
    }

    private func isPlistTargetingApp(plistPath: String, appPath: String, bundleId: String?) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return false
        }

        if let program = dict["Program"] as? String, program.hasPrefix(appPath) {
            return true
        }
        if let args = dict["ProgramArguments"] as? [String], let first = args.first, first.hasPrefix(appPath) {
            return true
        }
        if let bId = bundleId, let label = dict["Label"] as? String, label.contains(bId) {
            return true
        }
        return false
    }

    /// Automatically unloads and terminates launch daemons/agents before file removal
    public func preUninstallCleanup(items: [CleanItem]) {
        for item in items where item.path.hasSuffix(".plist") && (item.path.contains("LaunchAgents") || item.path.contains("LaunchDaemons")) {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["unload", "-w", item.path]
            try? task.run()
            task.waitUntilExit()
        }
    }
}

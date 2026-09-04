import Foundation
import Security

public struct AppUninstallBundle: Sendable {
    public let appName: String
    public let bundleId: String?
    public let appURL: URL
    public let associatedItems: [CleanItem]
    public let hasSystemExtensions: Bool
    
    public var totalSizeBytes: Int64 {
        return associatedItems.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var formattedTotalSize: String {
        return ByteFormatter.format(totalSizeBytes)
    }

    public init(
        appName: String,
        bundleId: String?,
        appURL: URL,
        associatedItems: [CleanItem],
        hasSystemExtensions: Bool = false
    ) {
        self.appName = appName
        self.bundleId = bundleId
        self.appURL = appURL
        self.associatedItems = associatedItems
        self.hasSystemExtensions = hasSystemExtensions
    }
}

public final class AppUninstaller: Sendable {
    public static let shared = AppUninstaller()

    public init() {}

    /// Extract App Groups from Code Signature Entitlements
    public func extractEntitlementsAppGroups(from appURL: URL) -> [String] {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(appURL as CFURL, [], &staticCode) == errSecSuccess,
              let code = staticCode else {
            return []
        }
        var signingInfo: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &signingInfo) == errSecSuccess,
              let info = signingInfo as? [String: Any] else {
            return []
        }
        if let entitlements = info[kSecCodeInfoEntitlementsDict as String] as? [String: Any] {
            if let groups = entitlements["com.apple.security.application-groups"] as? [String] {
                return groups
            }
        }
        return []
    }

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
            itemDescription: "应用程序二进制主包，位于 \(appURL.path)",
            associatedAppName: appName,
            isSelected: true
        ))

        // 2. Identify search tokens
        var searchTokens: Set<String> = [appName.lowercased()]
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
            // Add base domain prefix (e.g. com.khanov.Blocker for com.khanov.BlockerX)
            if subTokens.count >= 3 {
                let baseDomain = subTokens.dropLast().joined(separator: ".")
                searchTokens.insert(baseDomain)
            }
        }

        // Discover embedded app extensions (.appex)
        let pluginsDir = appURL.appendingPathComponent("Contents/PlugIns")
        if let plugins = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
            for plugin in plugins where plugin.pathExtension == "appex" {
                if let plugBundle = Bundle(url: plugin), let plugBId = plugBundle.bundleIdentifier?.lowercased() {
                    searchTokens.insert(plugBId)
                    if let last = plugBId.split(separator: ".").last {
                        searchTokens.insert(String(last))
                    }
                }
            }
        }

        // 3. Entitlements-driven App Groups Discovery (L1 Intelligence Layer)
        let appGroups = extractEntitlementsAppGroups(from: appURL)
        let groupContainersDir = FileUtils.expandPath("~/Library/Group Containers")
        for group in appGroups {
            let groupPath = (groupContainersDir as NSString).appendingPathComponent(group)
            if fileManager.fileExists(atPath: groupPath) && !whitelist.isProtected(path: groupPath, mode: .strict) {
                let size = FileUtils.calculateSize(atPath: groupPath)
                items.append(CleanItem(
                    name: "\(group) [App Group 共享沙盒]",
                    path: groupPath,
                    sizeBytes: max(size, 4096),
                    category: .orphanLeftovers,
                    safetyLevel: .caution,
                    itemDescription: "基于 Apple 代码签名 Entitlements 精准定位的共享沙盒目录",
                    associatedAppName: appName,
                    isSelected: false
                ))
            }
        }

        // Directories to inspect for app-specific leftovers (User & System-wide)
        let candidateDirectories: [(dir: String, cat: String, safety: SafetyLevel)] = [
            ("~/Library/Application Support", "配置与核心数据", .caution),
            ("~/Library/Application Scripts", "沙盒扩展脚本", .caution),
            ("~/Library/Caches", "运行缓存", .safe),
            ("~/Library/Containers", "沙盒隔离容器", .caution),
            ("~/Library/Group Containers", "共享数据组", .caution),
            ("~/Library/Preferences", "偏好设置文件", .caution),
            ("~/Library/Saved Application State", "退出窗口镜像", .safe),
            ("~/Library/WebKit", "内置网页缓存", .safe),
            ("~/Library/HTTPStorages", "网络缓存", .safe),
            ("~/Library/Logs", "运行日志", .safe),
            ("~/Library/CrashReporter", "崩溃报告", .safe),
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

        // 4. Spotlight (mdfind) Deep Search - L2 Intelligence Layer
        // Extracts all hidden files associated with the Bundle ID using macOS Spotlight
        if let bId = bundleId {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
            task.arguments = ["kMDItemCFBundleIdentifier == '\(bId)'"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            if let data = try? pipe.fileHandleForReading.readToEnd(),
               let output = String(data: data, encoding: .utf8) {
                let mdPaths = output.split(separator: "\n").map { String($0) }
                for mdPath in mdPaths {
                    if mdPath == appURL.path || whitelist.isProtected(path: mdPath, mode: .strict) { continue }
                    
                    // Check if we already added it
                    if !items.contains(where: { $0.path == mdPath }) {
                        let size = FileUtils.calculateSize(atPath: mdPath)
                        items.append(CleanItem(
                            name: (mdPath as NSString).lastPathComponent + " [Spotlight 深度追踪]",
                            path: mdPath,
                            sizeBytes: max(size, 4096),
                            category: .orphanLeftovers,
                            safetyLevel: .safe,
                            itemDescription: "基于底层 Spotlight 索引追踪到的散落关联文件",
                            associatedAppName: appName,
                            isSelected: true
                        ))
                    }
                }
            }
        }

        // 5. PKG Receipts Extraction (pkgutil) - L3 Intelligence Layer
        if let bId = bundleId {
            let pkgTask = Process()
            pkgTask.executableURL = URL(fileURLWithPath: "/usr/sbin/pkgutil")
            pkgTask.arguments = ["--pkgs=\(bId)"]
            
            let pkgPipe = Pipe()
            pkgTask.standardOutput = pkgPipe
            try? pkgTask.run()
            pkgTask.waitUntilExit()
            
            if pkgTask.terminationStatus == 0 {
                let fileTask = Process()
                fileTask.executableURL = URL(fileURLWithPath: "/usr/sbin/pkgutil")
                fileTask.arguments = ["--only-files", "--files", bId]
                let filePipe = Pipe()
                fileTask.standardOutput = filePipe
                try? fileTask.run()
                fileTask.waitUntilExit()
                
                if let data = try? filePipe.fileHandleForReading.readToEnd(),
                   let output = String(data: data, encoding: .utf8) {
                    let pkgFiles = output.split(separator: "\n").map { "/" + String($0) }
                    for pPath in pkgFiles {
                        if !fileManager.fileExists(atPath: pPath) || pPath.hasPrefix(appURL.path) || whitelist.isProtected(path: pPath, mode: .strict) { continue }
                        
                        if !items.contains(where: { $0.path == pPath }) {
                            let size = FileUtils.calculateSize(atPath: pPath)
                            items.append(CleanItem(
                                name: (pPath as NSString).lastPathComponent + " [PKG 安装收据]",
                                path: pPath,
                                sizeBytes: max(size, 4096),
                                category: .orphanLeftovers,
                                safetyLevel: .caution,
                                itemDescription: "通过 pkgutil 还原出的底层安装包残留文件",
                                associatedAppName: appName,
                                isSelected: true
                            ))
                        }
                    }
                }
            }
        }

        let sysExtDir = appURL.appendingPathComponent("Contents/Library/SystemExtensions").path
        let hasSysExt = fileManager.fileExists(atPath: sysExtDir)

        return AppUninstallBundle(
            appName: appName,
            bundleId: bundleId,
            appURL: appURL,
            associatedItems: items,
            hasSystemExtensions: hasSysExt
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

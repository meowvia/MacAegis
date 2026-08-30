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

        // Collect names and identifiers to search for
        var searchTokens = Set<String>()
        searchTokens.insert(appName.lowercased())
        if let bId = bundleId?.lowercased() {
            searchTokens.insert(bId)
            let subTokens = bId.split(separator: ".")
            if let last = subTokens.last {
                searchTokens.insert(String(last))
            }
        }

        // Directories to inspect for app-specific leftovers
        let candidateDirectories: [(dir: String, cat: String, safety: SafetyLevel)] = [
            ("~/Library/Application Support", "配置与核心数据", .safe),
            ("~/Library/Caches", "运行缓存", .safe),
            ("~/Library/Containers", "沙盒隔离容器", .safe),
            ("~/Library/Group Containers", "共享数据组", .caution),
            ("~/Library/Preferences", "偏好设置文件", .safe),
            ("~/Library/Saved Application State", "退出窗口镜像", .safe),
            ("~/Library/WebKit", "内置网页缓存", .safe),
            ("~/Library/HTTPStorages", "网络缓存", .safe),
            ("~/Library/Logs", "运行日志", .safe),
            ("~/Library/LaunchAgents", "自启守护脚本", .safe)
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
                    for token in searchTokens where token.count >= 3 {
                        if subLower == token || subLower.hasPrefix("\(token).") || subLower.hasSuffix(".\(token)") || subLower.contains(".\(token).") {
                            isMatch = true
                            break
                        }
                    }
                }

                if isMatch {
                    let fullPath = (expandedDir as NSString).appendingPathComponent(sub)
                    if whitelist.isProtected(path: fullPath) || fullPath == appURL.path {
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
                        associatedAppName: appName
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
}

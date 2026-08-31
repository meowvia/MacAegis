import Foundation
import AppKit

public struct OrphanHunterRules: CleanRuleProtocol {
    public let ruleId = "orphan_leftovers_hunter"
    public let displayName = "已卸载软件孤儿残留"
    public let category = CleanCategory.orphanLeftovers

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let appDetector = AppDetector.shared
        let whitelist = WhitelistManager.shared

        // Ensure installed apps are indexed
        _ = appDetector.indexInstalledApps()

        // 10 candidate directories across macOS user Library
        let candidateRoots: [(dir: String, nameSuffix: String, descSuffix: String, minBytes: Int64, safety: SafetyLevel)] = [
            ("~/Library/Application Support", "配置与支持数据", "已卸载软件的历史配置与核心支持数据", 500_000, .safe),
            ("~/Library/Containers", "沙盒残留容器", "沙盒应用卸载后未清理的独立运行沙盒目录", 500_000, .safe),
            ("~/Library/Caches", "运行缓存残留", "已卸载软件遗留的离线缓存与编译包", 1_000_000, .safe),
            ("~/Library/Preferences", "偏好设置残留", "已卸载软件的历史偏好设置属性文件", 1_000, .caution),
            ("~/Library/Saved Application State", "退出窗口状态镜像", "已卸载软件的窗口历史恢复快照", 10_000, .safe),
            ("~/Library/WebKit", "网页离线残留", "已卸载软件内置 Web 视图生成的离线缓存", 500_000, .safe),
            ("~/Library/HTTPStorages", "网络存储残留", "已卸载软件遗留的 HTTP 离线存储与 Cookie 镜像", 100_000, .safe),
            ("~/Library/Logs", "历史日志残留", "已卸载软件的历史运行排错文本", 50_000, .safe),
            ("~/Library/Group Containers", "共享数据残留", "已卸载应用组的共享媒体与离线数据", 1_000_000, .caution)
        ]

        for candidate in candidateRoots {
            let expandedRoot = FileUtils.expandPath(candidate.dir)
            guard let subdirs = try? fileManager.contentsOfDirectory(atPath: expandedRoot) else { continue }

            for sub in subdirs {
                if sub.hasPrefix(".") || sub.lowercased() == "apple" || sub.hasPrefix("com.apple.") || sub.hasPrefix("group.com.apple.") {
                    continue
                }
                let fullPath = (expandedRoot as NSString).appendingPathComponent(sub)
                if whitelist.isProtected(path: fullPath, mode: .strict) { continue }

                let checkName = sub.hasSuffix(".plist") ? (sub as NSString).deletingPathExtension : sub
                if isRealAppOrphan(directoryName: checkName, path: fullPath, appDetector: appDetector) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    if size >= candidate.minBytes {
                        let item = CleanItem(
                            name: "\(sub) \(candidate.nameSuffix)",
                            path: fullPath,
                            sizeBytes: max(size, 4096),
                            category: .orphanLeftovers,
                            safetyLevel: candidate.safety,
                            itemDescription: "\(candidate.descSuffix)，软件已被卸载，清理可释放宝贵磁盘空间。",
                            associatedAppName: checkName,
                            isSelected: candidate.safety == .safe
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // 10. Check ~/Library/LaunchAgents/ for dead startup daemons (with deep plist validation)
        let launchAgentsPath = FileUtils.expandPath("~/Library/LaunchAgents")
        if let agentFiles = try? fileManager.contentsOfDirectory(atPath: launchAgentsPath) {
            for file in agentFiles {
                if file.hasPrefix("com.apple.") || !file.hasSuffix(".plist") { continue }
                let fullPath = (launchAgentsPath as NSString).appendingPathComponent(file)
                if whitelist.isProtected(path: fullPath, mode: .strict) { continue }

                let baseName = (file as NSString).deletingPathExtension
                let isOrphanByApp = isRealAppOrphan(directoryName: baseName, path: fullPath, appDetector: appDetector)
                let isBrokenPlist = isBrokenLaunchAgent(plistPath: fullPath)

                if isOrphanByApp || isBrokenPlist {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    let item = CleanItem(
                        name: "\(file) 自启守护残留",
                        path: fullPath,
                        sizeBytes: max(size, 4096),
                        category: .orphanLeftovers,
                        safetyLevel: .safe,
                        itemDescription: "已卸载软件遗留的开机自启脚本配置，清理可防止无效的后台自启报错。",
                        associatedAppName: baseName,
                        isSelected: true
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        return items
    }

    private func isBrokenLaunchAgent(plistPath: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return false
        }

        if let program = dict["Program"] as? String {
            return !FileManager.default.fileExists(atPath: program)
        }
        if let args = dict["ProgramArguments"] as? [String], let first = args.first {
            return !FileManager.default.fileExists(atPath: first)
        }
        return false
    }

    private func isRealAppOrphan(directoryName: String, path: String, appDetector: AppDetector) -> Bool {
        // 1. Check indexed installed apps
        if appDetector.isAppInstalled(nameOrBundleId: directoryName) {
            return false
        }

        // 2. Check LaunchServices for registered bundle identifiers
        if directoryName.contains(".") {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: directoryName) != nil {
                return false
            }
        }

        // 3. Check Info.plist if present in the target directory
        let infoPlistPath = (path as NSString).appendingPathComponent("Info.plist")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let bId = plist["CFBundleIdentifier"] as? String {
            if appDetector.isAppInstalled(nameOrBundleId: bId) {
                return false
            }
        }

        return true
    }
}

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

        // 1. Check ~/Library/Application Support/
        let appSupportPath = FileUtils.expandPath("~/Library/Application Support")
        if let subdirs = try? fileManager.contentsOfDirectory(atPath: appSupportPath) {
            for sub in subdirs {
                if sub.hasPrefix(".") || sub.lowercased() == "apple" || sub.hasPrefix("com.apple.") {
                    continue
                }
                let fullPath = (appSupportPath as NSString).appendingPathComponent(sub)
                if whitelist.isProtected(path: fullPath) { continue }

                // Check if the app is truly an orphan across all system registries
                if isRealAppOrphan(directoryName: sub, path: fullPath, appDetector: appDetector) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    if size > 500_000 { // > 500KB
                        let item = CleanItem(
                            name: "\(sub) 遗留数据",
                            path: fullPath,
                            sizeBytes: size,
                            category: .orphanLeftovers,
                            safetyLevel: .safe,
                            itemDescription: "该软件肉身已在系统应用列表中被移除，但历史配置与支持数据仍留在电脑深层。",
                            associatedAppName: sub
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // 2. Check ~/Library/Containers/
        let containersPath = FileUtils.expandPath("~/Library/Containers")
        if let subdirs = try? fileManager.contentsOfDirectory(atPath: containersPath) {
            for sub in subdirs {
                if sub.hasPrefix("com.apple.") { continue }
                let fullPath = (containersPath as NSString).appendingPathComponent(sub)
                if whitelist.isProtected(path: fullPath) { continue }

                if isRealAppOrphan(directoryName: sub, path: fullPath, appDetector: appDetector) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    if size > 1_000_000 { // > 1MB
                        let item = CleanItem(
                            name: "\(sub) 沙盒残留容器",
                            path: fullPath,
                            sizeBytes: size,
                            category: .orphanLeftovers,
                            safetyLevel: .safe,
                            itemDescription: "沙盒应用卸载后未清理的独立运行沙盒残留目录。",
                            associatedAppName: sub
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // 3. Check ~/Library/LaunchAgents/ for dead startup daemons
        let launchAgentsPath = FileUtils.expandPath("~/Library/LaunchAgents")
        if let agentFiles = try? fileManager.contentsOfDirectory(atPath: launchAgentsPath) {
            for file in agentFiles {
                if file.hasPrefix("com.apple.") || !file.hasSuffix(".plist") { continue }
                let fullPath = (launchAgentsPath as NSString).appendingPathComponent(file)
                if whitelist.isProtected(path: fullPath) { continue }

                let baseName = (file as NSString).deletingPathExtension
                if isRealAppOrphan(directoryName: baseName, path: fullPath, appDetector: appDetector) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    let item = CleanItem(
                        name: "\(file) 自启守护残留",
                        path: fullPath,
                        sizeBytes: max(size, 4096),
                        category: .orphanLeftovers,
                        safetyLevel: .safe,
                        itemDescription: "已卸载软件遗留的开机自启脚本配置，清理可防止无效的后台自启报错。",
                        associatedAppName: baseName
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        return items
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

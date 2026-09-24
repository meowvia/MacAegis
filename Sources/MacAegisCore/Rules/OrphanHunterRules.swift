import Foundation
import AppKit

public struct OrphanHunterRules: CleanRuleProtocol {
    public let ruleId = "orphan_leftovers_hunter"
    public let displayName = "已卸载软件孤儿残留"
    public let category = CleanCategory.orphanLeftovers

    public init() {}

    private let systemInternalDirectoryNames: Set<String> = [
        "apple", "clouddocs", "fileprovider", "callhistorydb", "differentialprivacy",
        "syncservices", "btserver", "ilifemediabrowser", "addressbook", "accounts",
        "coretelephony", "crashreporter", "quick look", "dock", "proapps",
        "coreparsec", "knowledge", "speech", "frontboard", "sensorkit",
        "devicediscoveryui", "duetexpertcenter", "screentime", "audio",
        "coreaudio", "systempreferences", "com.apple", "automator",
        "fontcollections", "input methods", "keychains", "keyboard",
        "spelling", "fonts", "colors", "sounds", "speech", "preview",
        "macserialnumbers", "mobilesync", "identityservices", "help",
        "passbook", "security", "bluetooth", "preferences",
        "autobugcapture", "mcxtools", "mcxtools.log", "diagnosticreports",
        "system.log", "coreanalytics", "diskwiper"
    ]

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let appDetector = AppDetector.shared
        let whitelist = WhitelistManager.shared

        // Ensure installed apps are indexed
        _ = appDetector.indexInstalledApps()

        // 14 candidate directories across macOS user & system Library (expanded path matrix)
        let candidateRoots: [(dir: String, nameSuffix: String, descSuffix: String, minBytes: Int64, safety: SafetyLevel)] = [
            ("~/Library/Application Support", "配置与支持数据", "已卸载软件的历史配置与核心支持数据", 0, .safe),
            ("/Library/Application Support", "系统级配置与数据", "已卸载软件在全局目录遗留的配置与服务数据", 0, .caution),
            ("~/Library/Containers", "沙盒残留容器", "沙盒应用或扩展插件卸载后未清理的独立运行沙盒目录", 0, .safe),
            ("~/Library/Preferences", "偏好设置残留", "已卸载软件的历史偏好设置属性文件", 0, .caution),
            ("/Library/Preferences", "系统级偏好设置残留", "已卸载软件遗留的系统全局偏好设置属性文件", 0, .caution),
            ("~/Library/Saved Application State", "退出窗口状态镜像", "已卸载软件的窗口历史恢复快照", 0, .safe),
            ("~/Library/WebKit", "网页离线残留", "已卸载软件内置 Web 视图生成的离线缓存", 0, .safe),
            ("~/Library/HTTPStorages", "网络存储残留", "已卸载软件遗留的 HTTP 离线存储与 Cookie 镜像", 0, .safe),
            ("~/Library/Logs", "历史日志残留", "已卸载软件的历史运行排错文本", 0, .safe),
            ("/Library/Logs", "系统级日志残留", "已卸载软件的历史系统排错文本", 0, .caution),
            ("~/Library/Group Containers", "共享数据残留", "已卸载应用组的孤立共享数据", 0, .caution)
        ]

        for candidate in candidateRoots {
            let expandedRoot = FileUtils.expandPath(candidate.dir)
            guard let subdirs = try? fileManager.contentsOfDirectory(atPath: expandedRoot) else { continue }

            for sub in subdirs {
                let subLower = sub.lowercased()
                if sub.hasPrefix(".") || subLower.contains("macaegis") || subLower == "apple" || subLower.hasPrefix("com.apple.") || subLower.hasPrefix("group.com.apple.") {
                    continue
                }
                if systemInternalDirectoryNames.contains(subLower) {
                    continue
                }

                let fullPath = (expandedRoot as NSString).appendingPathComponent(sub)

                // Root privilege protection: If candidate is under /Library, do not scan if current user lacks deletion/write permissions
                if candidate.dir.hasPrefix("/Library") {
                    if !fileManager.isWritableFile(atPath: fullPath) && !fileManager.isDeletableFile(atPath: fullPath) {
                        continue
                    }
                }

                // Protect Group Containers: check live app reference
                if candidate.dir.contains("Group Containers") {
                    if appDetector.isGroupContainerInUse(groupName: sub) {
                        continue
                    }
                }

                // Protect Active Multi-App Vendor Root Folders
                if candidate.dir.contains("Application Support") {
                    if appDetector.isVendorDirectoryActive(vendorName: sub) {
                        continue
                    }
                }

                if whitelist.isProtected(path: fullPath, mode: .strict) { continue }

                var checkName = sub.hasSuffix(".plist") ? (sub as NSString).deletingPathExtension : (sub.hasSuffix(".savedState") ? (sub as NSString).deletingPathExtension : sub)
                var displayName = "\(sub) \(candidate.nameSuffix)"
                var associatedAppName = checkName

                if candidate.dir.contains("Containers") {
                    let (containerIdent, friendlyAppName) = resolveContainerMetadata(atPath: fullPath)
                    if let ident = containerIdent {
                        if ident.hasPrefix("com.apple.") || ident.hasPrefix("group.com.apple.") {
                            continue
                        }
                        checkName = ident
                        if let friendly = friendlyAppName {
                            displayName = "\(friendly) (\(ident)) \(candidate.nameSuffix)"
                            associatedAppName = friendly
                        } else {
                            displayName = "\(ident) \(candidate.nameSuffix)"
                            associatedAppName = ident
                        }
                    } else if sub.count == 36 && sub.contains("-") {
                        displayName = "扩展组件沙盒残留 (\(sub.prefix(8))...) \(candidate.nameSuffix)"
                    }
                }

                if isRealAppOrphan(directoryName: checkName, path: fullPath, appDetector: appDetector) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    if size >= candidate.minBytes {
                        let isSelectedByDefault = candidate.safety == .safe && !candidate.dir.contains("Group Containers")
                        let item = CleanItem(
                            name: displayName,
                            path: fullPath,
                            sizeBytes: max(size, 4096),
                            category: .orphanLeftovers,
                            safetyLevel: candidate.safety,
                            itemDescription: "\(candidate.descSuffix)，软件已被卸载，清理可释放宝贵磁盘空间。",
                            associatedAppName: associatedAppName,
                            isSelected: isSelectedByDefault
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // Check Startup Agents and Daemons across User and System
        let startupPaths = [
            FileUtils.expandPath("~/Library/LaunchAgents"),
            "/Library/LaunchAgents"
        ]

        for startupPath in startupPaths {
            guard let files = try? fileManager.contentsOfDirectory(atPath: startupPath) else { continue }
            for file in files {
                let fLower = file.lowercased()
                if fLower.hasPrefix("com.apple.") || fLower.contains("macaegis") || !fLower.hasSuffix(".plist") { continue }
                let fullPath = (startupPath as NSString).appendingPathComponent(file)
                if whitelist.isProtected(path: fullPath, mode: .strict) { continue }

                let baseName = (file as NSString).deletingPathExtension
                let isOrphanByApp = isRealAppOrphan(directoryName: baseName, path: fullPath, appDetector: appDetector)
                let isBrokenPlist = isBrokenLaunchScript(plistPath: fullPath)

                if isOrphanByApp || isBrokenPlist {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    let item = CleanItem(
                        name: "\(file) 自启守护残留",
                        path: fullPath,
                        sizeBytes: max(size, 4096),
                        category: .orphanLeftovers,
                        safetyLevel: startupPath.contains("/Library") ? .caution : .safe,
                        itemDescription: "已卸载软件遗留的后台自启守护脚本配置，清理可防止无效的后台自启报错。",
                        associatedAppName: baseName,
                        isSelected: !startupPath.contains("/Library")
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        return items
    }

    private func isBrokenLaunchScript(plistPath: String) -> Bool {
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

    private func resolveContainerMetadata(atPath containerPath: String) -> (identifier: String?, appName: String?) {
        let metaPath = (containerPath as NSString).appendingPathComponent(".com.apple.containermanagerd.metadata.plist")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: metaPath)),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            var ident = plist["MCMMetadataIdentifier"] as? String
            if ident == nil || ident?.isEmpty == true {
                if let valInfo = plist["MCMMetadataInfo"] as? [String: Any],
                   let subParams = (valInfo["SandboxProfileDataValidationInfo"] as? [String: Any])?["Parameters"] as? [String: Any],
                   let bid = subParams["application_bundle_id"] as? String {
                    ident = bid
                }
            }
            if let ident = ident, !ident.isEmpty {
                var friendlyName: String? = nil
                let lower = ident.lowercased()
                if lower.contains("readdle") { friendlyName = "Readdle Documents" }
                else if lower.contains("fleamarket") || lower.contains("taobao") { friendlyName = "闲鱼" }
                else if lower.contains("okex") { friendlyName = "OKX 欧易" }
                else if lower.contains("cloudflare") { friendlyName = "Cloudflare" }
                else if lower.contains("alarm") { friendlyName = "Alarm 闹钟" }
                else if lower.contains("comaps") { friendlyName = "Organic Maps" }
                else {
                    let parts = ident.split(separator: ".").map { String($0) }
                    if parts.count >= 3 {
                        friendlyName = parts[parts.count > 3 ? 2 : 1]
                    }
                }
                return (ident, friendlyName)
            }
        }
        return (nil, nil)
    }

    private func isRealAppOrphan(directoryName: String, path: String, appDetector: AppDetector) -> Bool {
        // 1. Check indexed installed apps directly
        if appDetector.isAppInstalled(nameOrBundleId: directoryName) {
            return false
        }

        // 2. Check LaunchServices for registered bundle identifiers
        if directoryName.contains(".") {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: directoryName) != nil {
                return false
            }

            // Dual-matching for extension identifiers like "com.samuellaska.AdBuster.Blocker"
            // or helper tools like "us.zoom.ZoomDaemon"
            let parts = directoryName.split(separator: ".").map { String($0) }
            if parts.count >= 3 {
                // e.g. parent bundle id "com.samuellaska.AdBuster"
                let parentBundleId = parts.prefix(parts.count - 1).joined(separator: ".")
                if appDetector.isAppInstalled(nameOrBundleId: parentBundleId) {
                    return false
                }
                // check if any component matches an installed app name
                for part in parts where part.count >= 4 {
                    if appDetector.isAppInstalled(nameOrBundleId: part) {
                        return false
                    }
                }
            }
        }

        // 3. Check Info.plist if present in the target directory
        let infoPlistPath = (path as NSString).appendingPathComponent("Info.plist")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            if let bId = plist["CFBundleIdentifier"] as? String, appDetector.isAppInstalled(nameOrBundleId: bId) {
                return false
            }
            if let bName = plist["CFBundleName"] as? String, appDetector.isAppInstalled(nameOrBundleId: bName) {
                return false
            }
        }

        return true
    }
}

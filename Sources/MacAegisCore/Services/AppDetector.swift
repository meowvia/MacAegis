import Foundation
import AppKit

public final class AppDetector: @unchecked Sendable {
    public static let shared = AppDetector()

    public struct InstalledApp: Sendable {
        public let name: String
        public let bundleId: String?
        public let bundleURL: URL
        public let normalizedNames: Set<String>
    }

    private var cachedApps: [InstalledApp] = []
    private var lastIndexTime: Date = .distantPast
    private let lock = NSLock()

    // Common directory alias mapping to real applications
    private let knownAppAliases: [String: [String]] = [
        "code": ["visualstudiocode", "com.microsoft.vscode", "code"],
        "cursor": ["cursor", "com.todesktop.230313mzl4w4u92", "cursor"],
        "google": ["googlechrome", "com.google.chrome", "chrome"],
        "microsoft": ["microsoftedge", "com.microsoft.edgemac", "microsoftword", "microsoftexcel"],
        "adobe": ["adobecreativecloud", "photoshop", "illustrator", "premiere"],
        "jetbrains": ["intellijidea", "pycharm", "webstorm", "goland", "datagrip", "clion"],
        "steam": ["steam", "com.valvesoftware.steam"],
        "spotify": ["spotify", "com.spotify.client"],
        "v2rayn": ["v2rayn", "com.v2rayn.v2rayn"],
        "docker": ["docker", "com.docker.docker"],
        "obsidian": ["obsidian", "md.obsidian"],
        "notion": ["notion", "notion.id"],
        "wechat": ["wechat", "com.tencent.xinwechat"],
        "qq": ["qq", "com.tencent.qq"]
    ]

    private init() {}

    /// Scan system and user application directories using lightweight plist parsing
    public func indexInstalledApps(forceRefresh: Bool = false) -> [InstalledApp] {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if !forceRefresh && !cachedApps.isEmpty && now.timeIntervalSince(lastIndexTime) < 5.0 {
            return cachedApps
        }

        var apps: [InstalledApp] = []
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            FileUtils.expandPath("~/Applications"),
            "/Applications/Utilities",
            "/System/Applications/Utilities",
            "/System/Library/CoreServices"
        ]

        let fileManager = FileManager.default

        for dir in searchDirectories {
            guard fileManager.fileExists(atPath: dir) else { continue }
            let dirURL = URL(fileURLWithPath: dir)

            guard let contents = try? fileManager.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for fileURL in contents {
                if fileURL.pathExtension.lowercased() == "app" {
                    autoreleasepool {
                        let appName = fileURL.deletingPathExtension().lastPathComponent
                        var bundleId: String? = nil

                        // Fast lightweight plist reading instead of heavy Bundle allocation
                        let infoPlistURL = fileURL.appendingPathComponent("Contents/Info.plist")
                        if let data = try? Data(contentsOf: infoPlistURL),
                           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                            bundleId = plist["CFBundleIdentifier"] as? String
                        }

                        var normalizedNames = Set<String>()
                        normalizedNames.insert(appName.lowercased())
                        normalizedNames.insert(appName.lowercased().replacingOccurrences(of: " ", with: ""))
                        normalizedNames.insert(appName.lowercased().replacingOccurrences(of: "-", with: ""))
                        normalizedNames.insert(appName.lowercased().replacingOccurrences(of: "_", with: ""))

                        if let bId = bundleId?.lowercased() {
                            normalizedNames.insert(bId)
                            let components = bId.split(separator: ".")
                            if let last = components.last {
                                normalizedNames.insert(String(last))
                            }
                        }

                        apps.append(InstalledApp(
                            name: appName,
                            bundleId: bundleId,
                            bundleURL: fileURL,
                            normalizedNames: normalizedNames
                        ))
                    }
                }
            }
        }

        self.cachedApps = apps
        self.lastIndexTime = Date()
        return apps
    }

    /// Check if a directory or bundle ID belongs to any currently installed app
    public func isAppInstalled(nameOrBundleId: String) -> Bool {
        let apps = indexInstalledApps()
        let target = nameOrBundleId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if target.hasPrefix("com.apple.") || target.hasPrefix("apple.") || target == "apple" {
            return true
        }

        // Check alias mapping first
        for (aliasKey, aliasTargets) in knownAppAliases {
            if target == aliasKey || target.contains(aliasKey) {
                for app in apps {
                    for aTarget in aliasTargets {
                        if app.normalizedNames.contains(aTarget) {
                            return true
                        }
                    }
                }
            }
        }

        let targetClean = target.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")

        for app in apps {
            if app.normalizedNames.contains(target) || app.normalizedNames.contains(targetClean) {
                return true
            }
            if let bundleId = app.bundleId?.lowercased() {
                if bundleId == target || target.contains(bundleId) {
                    return true
                }
                // Check component-based match to avoid false positive substring matches
                let components = bundleId.split(separator: ".").map { String($0) }
                if components.contains(target) || components.contains(targetClean) {
                    return true
                }
                if target.count >= 4 && bundleId.contains(target) {
                    return true
                }
            }
            if app.name.lowercased() == target {
                return true
            }
        }

        // System-Level LaunchServices Live Registration Check
        if target.contains(".") {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: target) != nil {
                return true
            }
        }

        return false
    }

    /// Check whether a Group Container (e.g. FN2V63AD2J.com.tencent) belongs to any currently installed app
    public func isGroupContainerInUse(groupName: String) -> Bool {
        let gLower = groupName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if gLower.contains("apple") || gLower.hasPrefix("group.com.apple.") {
            return true
        }

        let apps = indexInstalledApps()

        // 1. Check known multi-app vendor groups
        if gLower.contains("tencent") {
            if apps.contains(where: { $0.bundleId?.lowercased().contains("tencent") == true }) {
                return true
            }
        }
        if gLower.contains("microsoft") || gLower.contains("office") {
            if apps.contains(where: { $0.bundleId?.lowercased().contains("microsoft") == true }) {
                return true
            }
        }
        if gLower.contains("google") {
            if apps.contains(where: { $0.bundleId?.lowercased().contains("google") == true || $0.name.lowercased().contains("chrome") }) {
                return true
            }
        }
        if gLower.contains("adobe") {
            if apps.contains(where: { $0.bundleId?.lowercased().contains("adobe") == true }) {
                return true
            }
        }

        // 2. Extract potential bundle or domain tokens from groupName (e.g. "FN2V63AD2J.com.tencent" -> "com.tencent")
        let parts = gLower.split(separator: ".").map { String($0) }
        for app in apps {
            guard let bId = app.bundleId?.lowercased(), bId.count >= 5, bId.contains(".") else { continue }
            
            // If group name contains the exact app's bundle ID as a qualified token
            if gLower == bId || gLower.hasSuffix("." + bId) || gLower.contains("." + bId + ".") {
                return true
            }
            
            // Check domain token (e.g. "com.tencent")
            if parts.count >= 2 {
                // Ignore the leading team ID if alphanumeric 10 chars
                let candidateParts = (parts.first?.count == 10 && parts.first?.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil) ? Array(parts.dropFirst()) : parts
                let candidateDomain = candidateParts.joined(separator: ".")
                if candidateDomain.count >= 6 && (bId.hasPrefix(candidateDomain) || candidateDomain.hasPrefix(bId)) {
                    return true
                }
            }
        }

        // 3. Check App Signature Entitlements
        for app in apps {
            let appGroups = AppUninstaller.shared.extractEntitlementsAppGroups(from: app.bundleURL)
            if appGroups.contains(where: { $0.lowercased() == gLower }) {
                return true
            }
        }

        return false
    }

    /// Check if a directory is a known multi-app vendor directory that still hosts active apps
    public func isVendorDirectoryActive(vendorName: String) -> Bool {
        let vLower = vendorName.lowercased()
        let apps = indexInstalledApps()
        switch vLower {
        case "google":
            return apps.contains { $0.bundleId?.lowercased().contains("google") == true || $0.name.lowercased().contains("chrome") }
        case "microsoft":
            return apps.contains { $0.bundleId?.lowercased().contains("microsoft") == true || $0.name.lowercased().contains("edge") }
        case "adobe":
            return apps.contains { $0.bundleId?.lowercased().contains("adobe") == true || $0.name.lowercased().contains("photoshop") }
        case "jetbrains":
            return apps.contains { $0.bundleId?.lowercased().contains("jetbrains") == true }
        case "logi", "logitech", "logitech.localized":
            return apps.contains { $0.bundleId?.lowercased().contains("logi") == true || $0.name.lowercased().contains("logi") }
        case "tencent":
            return apps.contains { $0.bundleId?.lowercased().contains("tencent") == true }
        default:
            return false
        }
    }
}

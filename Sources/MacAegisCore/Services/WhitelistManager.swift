import Foundation

public enum ProtectionMode: Sendable {
    case strict
    case cacheOnly
}

public final class WhitelistManager: @unchecked Sendable {
    public static let shared = WhitelistManager()

    /// Absolute protected system paths - NEVER touched under any circumstance or mode
    private let absoluteProtectedPaths: Set<String> = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/var",
        "/private",
        "/Library/Security",
        "/Library/Keychains",
        "/Library/Apple",
        "/Volumes/Macintosh HD",

        // Critical user identity and cloud files
        "~/Library/Keychains",
        "~/Library/Safari",
        "~/Library/IdentityServices",
        "~/Library/Accounts",
        "~/Library/Mail",
        "~/Library/Messages",
        "~/Library/Photos",
        "~/Library/Cookies",
        "~/Library/Passes",
        "~/Library/Mobile Documents", // iCloud Drive
        "~/Library/CloudStorage",
        "~/Library/HomeKit",
        "~/Library/Calendars",
        "~/Library/Reminders",
        "~/Library/Notes",
        "~/Library/PersonalizationPortrait",
        "~/Library/Suggestions",
        "~/Library/Application Support/MacAegis"
    ]

    /// Essential app data directories that must not be deleted as an entire bundle,
    /// but whose specific cache/temp subpaths can be cleaned under .cacheOnly mode.
    private let protectedContainers: Set<String> = [
        "~/Library/Application Support/Code",
        "~/Library/Application Support/Cursor",
        "~/Library/Application Support/Google",
        "~/Library/Application Support/Microsoft",
        "~/Library/Application Support/Adobe",
        "~/Library/Application Support/JetBrains",
        "~/Library/Application Support/Steam",
        "~/Library/Application Support/Obsidian",
        "~/Library/Application Support/Notion",
        "~/Library/Application Support/Docker Desktop",
        "~/Library/Application Support/v2rayN",
        "~/Library/Application Support/Telegram Desktop",
        "~/Library/Containers/com.tencent.xinWeChat",
        "~/Library/Group Containers"
    ]

    /// Specific folder roots that cannot be deleted themselves
    private let protectedContainerRoots: Set<String> = [
        "~/Desktop",
        "~/Documents",
        "~/Pictures",
        "~/Music",
        "~/Movies",
        "~/Downloads",
        "~/Library/Caches",
        "~/Library/Logs",
        "~/Library/Group Containers",
        "~/Library/Preferences",
        "~/Library/Containers",
        "~/Library/Application Support"
    ]

    /// Recognized safe cache subpath indicators that are permitted to be cleaned inside protected containers
    private let allowedCacheSubpathKeywords: [String] = [
        "/Cache/", "/Caches/", "/GPUCache/", "/Code Cache/", "/ScriptCache/",
        "/CacheStorage/", "/tmp/", "/temp/", "/Crashpad/", "/Logs/",
        "/HTTPStorages/", "/Service Worker/CacheStorage/", "/tdata/user_data/cache",
        "/tdata/temp", "/Data/Library/Caches/"
    ]

    /// Critical file extensions and names that must never be deleted anywhere
    private let protectedFileExtensions: Set<String> = [
        "db", "sqlite", "sqlite3", "sqlite-wal", "sqlite-shm",
        "keychain", "keychain-db",
        "pem", "p12", "crt", "cer", "key",
        "env", "credentials"
    ]

    private var customWhitelist: Set<String> = []
    private let configPath = FileUtils.expandPath("~/.config/macaegis/whitelist")
    private let lock = NSLock()

    private init() {
        loadCustomWhitelist()
    }

    private func loadCustomWhitelist() {
        if FileManager.default.fileExists(atPath: configPath) {
            do {
                let content = try String(contentsOfFile: configPath, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                customWhitelist = Set(lines.map { FileUtils.expandPath($0) })
            } catch {
                customWhitelist = []
            }
        }
    }

    /// Check whether a given path is protected under specified protection mode
    public func isProtected(path: String, mode: ProtectionMode = .strict) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let expanded = FileUtils.expandPath(path)

        // 1. Prevent wiping root or home directory
        if expanded == "/" || expanded == FileUtils.expandPath("~") {
            return true
        }

        // 2. Prevent deleting container roots themselves (e.g. wiping entire ~/Downloads or ~/Library/Caches)
        for root in protectedContainerRoots {
            if expanded == FileUtils.expandPath(root) {
                return true
            }
        }

        // 3. Check protected file extensions (never touch database, keys, certs anywhere)
        let ext = (expanded as NSString).pathExtension.lowercased()
        if protectedFileExtensions.contains(ext) {
            return true
        }

        // 4. Check absolute protected system paths (full subtree protection under all modes)
        for sysPath in absoluteProtectedPaths {
            let expandedSys = FileUtils.expandPath(sysPath)
            if expanded == expandedSys || expanded.hasPrefix(expandedSys + "/") {
                return true
            }
        }

        // 5. Check custom user whitelist
        for customPath in customWhitelist {
            if expanded == customPath || expanded.hasPrefix(customPath + "/") {
                return true
            }
        }

        // 6. Check protected containers according to mode
        for container in protectedContainers {
            let expContainer = FileUtils.expandPath(container)
            if expanded == expContainer {
                return true
            }
            if expanded.hasPrefix(expContainer + "/") {
                if mode == .cacheOnly {
                    // Under .cacheOnly mode, verify if this specific target path is a safe cache subpath
                    let containsCacheKeyword = allowedCacheSubpathKeywords.contains { expanded.contains($0) }
                    if containsCacheKeyword || expanded.hasSuffix("/Cache") || expanded.hasSuffix("/Caches") || expanded.hasSuffix("/GPUCache") || expanded.hasSuffix("/Code Cache") {
                        return false // Allow cleaning safe cache subpaths!
                    }
                }
                return true // Protect user configs and non-cache data
            }
        }

        return false
    }

    public func addToWhitelist(path: String) throws {
        lock.lock()
        defer { lock.unlock() }

        let expanded = FileUtils.expandPath(path)
        customWhitelist.insert(expanded)

        let dir = (configPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let content = customWhitelist.joined(separator: "\n")
        try content.write(toFile: configPath, atomically: true, encoding: .utf8)
    }
}

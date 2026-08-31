import Foundation

public final class WhitelistManager: @unchecked Sendable {
    public static let shared = WhitelistManager()

    /// Directories whose whole tree must NEVER be touched under any circumstances
    private let systemProtectedPaths: Set<String> = [
        // User Personal Data Directories
        "~/Desktop",
        "~/Documents",
        "~/Pictures",
        "~/Music",
        "~/Movies",
        "~/Public",

        // Apple Critical System & Cloud Storage
        "~/Library/Keychains",
        "~/Library/Safari",
        "~/Library/IdentityServices",
        "~/Library/Accounts",
        "~/Library/Mail",
        "~/Library/Messages",
        "~/Library/Photos",
        "~/Library/Mobile Documents", // iCloud Drive
        "~/Library/CloudStorage",
        "~/Library/HomeKit",
        "~/Library/Calendars",
        "~/Library/Reminders",
        "~/Library/Notes",
        "~/Library/Cookies",
        "~/Library/Passes",
        "~/Library/PersonalizationPortrait",
        "~/Library/Suggestions",

        // Essential App Data & IDEs (NEVER consider as trash or orphan)
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
        "~/Library/Application Support/MacAegis",
        "~/Library/Containers/com.tencent.xinWeChat",

        // Root & System Directories
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
        "/Volumes/Macintosh HD"
    ]

    /// Specific folder paths that cannot be deleted itself, but individual cache/installer files inside may be cleaned
    private let protectedContainerRoots: Set<String> = [
        "~/Downloads",
        "~/Library/Caches",
        "~/Library/Logs",
        "~/Library/Group Containers",
        "~/Library/Preferences"
    ]

    /// Critical file extensions and names that must never be deleted
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

    /// Absolute check whether a given path is protected
    public func isProtected(path: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let expanded = FileUtils.expandPath(path)

        // 1. Prevent wiping root or home directory
        if expanded == "/" || expanded == FileUtils.expandPath("~") {
            return true
        }

        // 2. Prevent deleting container roots themselves (e.g. wiping the entire ~/Downloads folder)
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

        // 4. Check protected system paths (full subtree protection)
        for sysPath in systemProtectedPaths {
            let expandedSys = FileUtils.expandPath(sysPath)
            if expanded == expandedSys || expanded.hasPrefix(expandedSys + "/") {
                return true
            }
        }

        // 5. Check custom whitelist
        for customPath in customWhitelist {
            if expanded == customPath || expanded.hasPrefix(customPath + "/") {
                return true
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

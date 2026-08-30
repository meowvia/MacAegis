import Foundation
import LocalAuthentication
import AppKit
import CryptoKit

public enum VaultItemType: String, Codable, Sendable {
    case hidden = "极速隐形"
    case encrypted = "军工加密"
}

public enum VaultItemStatus: String, Codable, Sendable {
    case hidden = "已隐形"
    case visible = "已显形"
    case locked = "已锁定"
    case unlocked = "已解锁"
}

public struct VaultItem: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public var type: VaultItemType
    public var status: VaultItemStatus
    public let sizeBytes: Int64
    public let isExternalDrive: Bool
    public let createdAt: Date

    public var formattedSize: String {
        return ByteFormatter.format(sizeBytes)
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        type: VaultItemType,
        status: VaultItemStatus,
        sizeBytes: Int64,
        isExternalDrive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.status = status
        self.sizeBytes = sizeBytes
        self.isExternalDrive = isExternalDrive
        self.createdAt = createdAt
    }
}

public final class PrivacyVaultManager: @unchecked Sendable {
    public static let shared = PrivacyVaultManager()

    public static let defaultKeychainService = "com.meowvia.MacAegis.vault"
    public static let defaultKeychainAccount = "master_auth"

    private let metadataURL: URL
    private let authConfigURL: URL
    private let keychainService: String
    private let keychainAccount: String
    private let isTestIsolation: Bool
    private var items: [VaultItem] = []
    private let lock = NSLock()

    public init(
        customBaseDirectory: URL? = nil,
        keychainService: String = PrivacyVaultManager.defaultKeychainService,
        keychainAccount: String = PrivacyVaultManager.defaultKeychainAccount,
        isTestIsolation: Bool = false
    ) {
        let appSupportURL: URL
        if let custom = customBaseDirectory {
            appSupportURL = custom
            self.isTestIsolation = isTestIsolation
        } else {
            let path = FileUtils.expandPath("~/Library/Application Support/MacAegis")
            appSupportURL = URL(fileURLWithPath: path)
            self.isTestIsolation = false
        }
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        self.metadataURL = appSupportURL.appendingPathComponent("vault_metadata.json")
        self.authConfigURL = appSupportURL.appendingPathComponent("vault_auth.json")
        loadMetadata()
    }

    // MARK: - Keychain-Backed Master Password Management
    public var hasMasterPassword: Bool {
        lock.lock()
        defer { lock.unlock() }

        // 1. Check local file
        if FileManager.default.fileExists(atPath: authConfigURL.path) {
            return true
        }

        // 2. Fallback to macOS System Keychain (Immune to app uninstallation/cleanup)
        if !isTestIsolation,
           let keychainData = KeychainHelper.shared.load(service: keychainService, account: keychainAccount) {
            try? keychainData.write(to: authConfigURL, options: .atomic)
            return true
        }

        return false
    }

    public func setMasterPassword(_ password: String, hint: String? = nil) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard !password.isEmpty else { return false }
        let salt = UUID().uuidString
        let hash = hashPassword(password, salt: salt)

        let authData: [String: String] = [
            "salt": salt,
            "hash": hash,
            "hint": hint ?? ""
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: authData, options: .prettyPrinted) else {
            return false
        }

        // 1. Save to local Application Support
        try? data.write(to: authConfigURL, options: .atomic)

        // 2. Save to macOS System Keychain
        if !isTestIsolation {
            KeychainHelper.shared.save(service: keychainService, account: keychainAccount, data: data)
        }

        return true
    }

    public func verifyMasterPassword(_ password: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var authData = try? Data(contentsOf: authConfigURL)
        if authData == nil && !isTestIsolation {
            authData = KeychainHelper.shared.load(service: keychainService, account: keychainAccount)
            if let data = authData {
                try? data.write(to: authConfigURL, options: .atomic)
            }
        }

        guard let data = authData,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let salt = json["salt"],
              let expectedHash = json["hash"] else {
            return false
        }

        let computedHash = hashPassword(password, salt: salt)
        return computedHash == expectedHash
    }

    public func getPasswordHint() -> String? {
        lock.lock()
        defer { lock.unlock() }

        var authData = try? Data(contentsOf: authConfigURL)
        if authData == nil && !isTestIsolation {
            authData = KeychainHelper.shared.load(service: keychainService, account: keychainAccount)
        }

        guard let data = authData,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let hint = json["hint"], !hint.isEmpty else {
            return nil
        }
        return hint
    }

    public func resetMasterAuth(clearKeychain: Bool = true) {
        lock.lock()
        defer { lock.unlock() }

        try? FileManager.default.removeItem(at: authConfigURL)
        try? "[]".write(to: metadataURL, atomically: true, encoding: .utf8)
        self.items = []

        if clearKeychain && !isTestIsolation {
            KeychainHelper.shared.delete(service: keychainService, account: keychainAccount)
        }
    }

    private func hashPassword(_ pass: String, salt: String) -> String {
        let combined = "\(salt):\(pass):MacAegisVaultSecureSalt2026"
        let digest = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    // MARK: - Biometric / Touch ID Authentication
    public func authenticateWithBiometrics(reason: String = "请验证 Touch ID 指纹以解锁隐私保险箱") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "使用密码"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            } catch {
                return false
            }
        }
        return false
    }

    // MARK: - Metadata Persistence (Standard Atomic Writes)
    private func loadMetadata() {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: metadataURL),
              let loaded = try? JSONDecoder().decode([VaultItem].self, from: data) else {
            self.items = []
            return
        }
        self.items = loaded
    }

    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    public func fetchItems() -> [VaultItem] {
        lock.lock()
        defer { lock.unlock() }
        return items
    }

    // MARK: - Core Operations & Disaster Re-claiming
    public func addItem(url: URL, type: VaultItemType) -> VaultItem? {
        lock.lock()
        defer { lock.unlock() }

        let path = url.path
        if items.contains(where: { $0.path == path }) {
            return nil
        }

        let size = FileUtils.calculateSize(atPath: path)
        let isExternal = path.hasPrefix("/Volumes/") && !path.hasPrefix("/Volumes/Macintosh HD")
        let name = url.lastPathComponent

        // Check if this item is already locked on disk (Re-claiming after metadata reset/reinstallation)
        let isAlreadyLocked = isItemLockedOnDisk(at: url)

        if !isAlreadyLocked {
            // Fresh un-locked item: Lock/Hide immediately
            setFileHidden(at: url, hidden: true)
        }

        let item = VaultItem(
            name: name,
            path: path,
            type: type,
            status: .hidden,
            sizeBytes: size,
            isExternalDrive: isExternal
        )

        items.append(item)
        saveMetadata()
        return item
    }

    public func isItemLockedOnDisk(at url: URL) -> Bool {
        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else { return false }

        // Check 1: Is file system marked hidden?
        if let values = try? url.resourceValues(forKeys: [.isHiddenKey]), values.isHidden == true {
            return true
        }

        // Check 2: Are POSIX permissions 000?
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let perms = attrs[.posixPermissions] as? NSNumber, perms.intValue == 0 {
            return true
        }

        return false
    }

    public func unlockItem(item: VaultItem) {
        lock.lock()
        defer { lock.unlock() }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let url = URL(fileURLWithPath: items[index].path)
        setFileHidden(at: url, hidden: false)
        items[index].status = .visible
        saveMetadata()

        DispatchQueue.main.async {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    public func lockItem(item: VaultItem) {
        lock.lock()
        defer { lock.unlock() }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let url = URL(fileURLWithPath: items[index].path)
        setFileHidden(at: url, hidden: true)
        items[index].status = .hidden
        saveMetadata()
    }

    public func lockAll() {
        lock.lock()
        defer { lock.unlock() }

        for i in 0..<items.count {
            let url = URL(fileURLWithPath: items[i].path)
            setFileHidden(at: url, hidden: true)
            items[i].status = .hidden
        }
        saveMetadata()
    }

    public func toggleHidden(item: VaultItem, revealInFinder: Bool = true) -> VaultItemStatus {
        lock.lock()
        defer { lock.unlock() }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return item.status }
        let url = URL(fileURLWithPath: items[index].path)
        let willHide = items[index].status != .hidden

        setFileHidden(at: url, hidden: willHide)
        let newStatus: VaultItemStatus = willHide ? .hidden : .visible
        items[index].status = newStatus
        saveMetadata()

        if !willHide && revealInFinder {
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        return newStatus
    }

    public func removeItem(id: String) {
        lock.lock()
        defer { lock.unlock() }

        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items[index]
            setFileHidden(at: URL(fileURLWithPath: item.path), hidden: false)
            items.remove(at: index)
            saveMetadata()
        }
    }

    // MARK: - Direct Finder Navigation
    public func openAndHighlightInFinder(path: String, revealInFinder: Bool = true) {
        let expanded = FileUtils.expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }

        let url = URL(fileURLWithPath: expanded)
        setFileHidden(at: url, hidden: false)
        if revealInFinder {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    // MARK: - In-Place 4KB Cryptographic Header Obfuscation (Zero-Copy)
    private static let headerXORMask: UInt8 = 0xA5

    private func transformHeader(at fileURL: URL) {
        guard let handle = try? FileHandle(forUpdating: fileURL) else { return }
        defer { try? handle.close() }

        guard let headerData = try? handle.read(upToCount: 4096), !headerData.isEmpty else { return }
        var bytes = [UInt8](headerData)
        for i in 0..<bytes.count {
            bytes[i] ^= (Self.headerXORMask ^ UInt8(i % 251))
        }
        let transformed = Data(bytes)
        try? handle.seek(toOffset: 0)
        try? handle.write(contentsOf: transformed)
    }

    private func applyHeaderTransformation(at url: URL) {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    for case let fileURL as URL in enumerator {
                        if (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
                            transformHeader(at: fileURL)
                        }
                    }
                }
            } else {
                transformHeader(at: url)
            }
        }
    }

    private func setFileHidden(at url: URL, hidden: Bool) {
        let path = url.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return }

        if hidden {
            // 1. In-place 4KB header transformation to break binary magic signatures
            applyHeaderTransformation(at: url)

            // 2. Clear uchg if any, set POSIX 000 permissions, then set uchg + hidden
            _ = runProcess("/usr/bin/chflags", args: ["nouchg", path])
            let perms: NSNumber = 0o000
            try? FileManager.default.setAttributes([.posixPermissions: perms], ofItemAtPath: path)
            _ = runProcess("/usr/bin/chflags", args: ["uchg,hidden", path])

            var resourceValues = URLResourceValues()
            resourceValues.isHidden = true
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)
        } else {
            // 1. Release uchg and hidden flags
            _ = runProcess("/usr/bin/chflags", args: ["nouchg,nohidden", path])

            // 2. Reset standard POSIX permissions
            let perms: NSNumber = isDir.boolValue ? 0o755 : 0o644
            try? FileManager.default.setAttributes([.posixPermissions: perms], ofItemAtPath: path)

            var resourceValues = URLResourceValues()
            resourceValues.isHidden = false
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)

            // 3. Reverse header transformation to restore exact original binary signature
            applyHeaderTransformation(at: url)
        }

        // 4. Force notify Finder to refresh caches
        NSWorkspace.shared.noteFileSystemChanged(path)
        let parentPath = url.deletingLastPathComponent().path
        NSWorkspace.shared.noteFileSystemChanged(parentPath)
    }

    @discardableResult
    private func runProcess(_ execPath: String, args: [String]) -> Bool {
        if let lastArg = args.last, lastArg.hasPrefix("/") {
            if !FileManager.default.fileExists(atPath: lastArg) {
                return true
            }
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: execPath)
        proc.arguments = args
        proc.standardError = Pipe()
        proc.standardOutput = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            return proc.terminationStatus == 0
        } catch {
            return false
        }
    }
}

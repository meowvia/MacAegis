import Foundation
import LocalAuthentication
import AppKit
import CryptoKit
import CommonCrypto

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
    public static let xattrVaultKey = "com.meowvia.macaegis.vault"

    private let metadataURL: URL
    private let authConfigURL: URL
    private let keychainService: String
    private let keychainAccount: String
    private let isTestIsolation: Bool
    private var items: [VaultItem] = []
    private var activeDerivedKey: Data?
    private var activeSaltHex: String = ""
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

    // MARK: - Cryptographic Key Derivation (PBKDF2-HMAC-SHA256, 100,000 Iterations)
    public static func generateRandomSalt(length: Int = 16) -> Data {
        var salt = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &salt)
        return Data(salt)
    }

    public static func deriveKeyPBKDF2(password: String, salt: Data, iterations: UInt32 = 100_000) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        var derivedKey = [UInt8](repeating: 0, count: 32)
        
        let result = salt.withUnsafeBytes { saltBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    passwordData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derivedKey,
                    derivedKey.count
                )
            }
        }
        
        guard result == kCCSuccess else { return nil }
        return Data(derivedKey)
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
        let saltData = Self.generateRandomSalt(length: 16)
        let saltHex = saltData.map { String(format: "%02hhx", $0) }.joined()

        guard let derivedKey = Self.deriveKeyPBKDF2(password: password, salt: saltData, iterations: 100_000) else {
            return false
        }
        self.activeDerivedKey = derivedKey
        self.activeSaltHex = saltHex

        let keyHash = derivedKey.map { String(format: "%02hhx", $0) }.joined()

        let authData: [String: String] = [
            "salt": saltHex,
            "hash": keyHash,
            "hint": hint ?? ""
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: authData, options: .prettyPrinted) else {
            return false
        }

        // 1. Save to local Application Support
        try? data.write(to: authConfigURL, options: .atomic)

        // 2. Save permanently to macOS System Keychain
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
              let saltHex = json["salt"],
              let expectedHash = json["hash"] else {
            return false
        }

        guard let saltData = Data(hexString: saltHex),
              let derivedKey = Self.deriveKeyPBKDF2(password: password, salt: saltData, iterations: 100_000) else {
            return false
        }

        let computedHash = derivedKey.map { String(format: "%02hhx", $0) }.joined()
        if computedHash == expectedHash {
            self.activeDerivedKey = derivedKey
            self.activeSaltHex = saltHex
            return true
        }
        return false
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
        self.activeDerivedKey = nil
        self.activeSaltHex = ""

        if clearKeychain && !isTestIsolation {
            KeychainHelper.shared.delete(service: keychainService, account: keychainAccount)
        }
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

    // MARK: - macOS Native Extended Attributes (xattr) Management
    @discardableResult
    private func setVaultXattr(at path: String, saltHex: String) -> Bool {
        guard let data = saltHex.data(using: .utf8) else { return false }
        return data.withUnsafeBytes { bytes in
            let res = setxattr(path, Self.xattrVaultKey, bytes.baseAddress, data.count, 0, 0)
            return res == 0
        }
    }

    public func getVaultXattr(at path: String) -> String? {
        var length = getxattr(path, Self.xattrVaultKey, nil, 0, 0, 0)
        if length < 0 && (errno == EACCES || errno == EPERM) {
            var statBuf = stat()
            if lstat(path, &statBuf) == 0 {
                let originalMode = statBuf.st_mode
                _ = runProcess("/usr/bin/chflags", args: ["nouchg", path])
                chmod(path, 0o700)
                length = getxattr(path, Self.xattrVaultKey, nil, 0, 0, 0)
                if length > 0 {
                    var data = Data(count: length)
                    _ = data.withUnsafeMutableBytes { bytes in
                        getxattr(path, Self.xattrVaultKey, bytes.baseAddress, length, 0, 0)
                    }
                    chmod(path, originalMode)
                    _ = runProcess("/usr/bin/chflags", args: ["uchg,hidden", path])
                    return String(data: data, encoding: .utf8)
                }
                chmod(path, originalMode)
                _ = runProcess("/usr/bin/chflags", args: ["uchg,hidden", path])
            }
        }
        guard length > 0 else { return nil }
        var data = Data(count: length)
        let readLen = data.withUnsafeMutableBytes { bytes in
            getxattr(path, Self.xattrVaultKey, bytes.baseAddress, length, 0, 0)
        }
        guard readLen > 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func hasVaultXattr(at path: String) -> Bool {
        return getVaultXattr(at: path) != nil
    }

    @discardableResult
    private func removeVaultXattr(at path: String) -> Bool {
        return removexattr(path, Self.xattrVaultKey, 0) == 0
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

        // Strict Check: Primary criterion is presence of MacAegis xattr signature
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

        // Primary Criterion: Strict Apple Extended Attribute Signature
        if hasVaultXattr(at: path) {
            return true
        }

        // Secondary Fallback Verification: POSIX 000 permissions AND isHidden
        if let values = try? url.resourceValues(forKeys: [.isHiddenKey]), values.isHidden == true,
           let attrs = try? FileManager.default.attributesOfItem(atPath: path),
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

    // MARK: - In-Place 4KB Dynamic PBKDF2 Key-Derived Header Stream Obfuscation
    private static let fallbackHeaderMask: UInt8 = 0xA5

    private func transformHeader(at fileURL: URL, derivedKey: Data?) {
        guard let handle = try? FileHandle(forUpdating: fileURL) else { return }
        defer { try? handle.close() }

        guard let headerData = try? handle.read(upToCount: 4096), !headerData.isEmpty else { return }
        var bytes = [UInt8](headerData)
        let keyBytes = derivedKey != nil && !derivedKey!.isEmpty ? [UInt8](derivedKey!) : [Self.fallbackHeaderMask]
        let keyLen = keyBytes.count

        for i in 0..<bytes.count {
            let mask = keyBytes[i % keyLen]
            bytes[i] ^= mask
        }
        let transformed = Data(bytes)
        try? handle.seek(toOffset: 0)
        try? handle.write(contentsOf: transformed)
    }

    private func applyHeaderTransformation(at url: URL) {
        let key = activeDerivedKey
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    for case let fileURL as URL in enumerator {
                        if (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
                            transformHeader(at: fileURL, derivedKey: key)
                        }
                    }
                }
            } else {
                transformHeader(at: url, derivedKey: key)
            }
        }
    }

    private func setFileHidden(at url: URL, hidden: Bool) {
        let path = url.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return }

        if hidden {
            // 1. In-place 4KB header transformation using PBKDF2 derived stream
            applyHeaderTransformation(at: url)

            // 2. Mark native macOS Extended Attribute (xattr) BEFORE changing permissions
            let salt = activeSaltHex.isEmpty ? "MacAegisLocked" : activeSaltHex
            setVaultXattr(at: path, saltHex: salt)

            // 3. Clear uchg if any, set POSIX 000 permissions, then set uchg + hidden
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

            // 3. Remove native macOS Extended Attribute (xattr) AFTER restoring permissions
            removeVaultXattr(at: path)

            var resourceValues = URLResourceValues()
            resourceValues.isHidden = false
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)

            // 4. Reverse header transformation to restore exact original binary signature
            applyHeaderTransformation(at: url)
        }

        // 5. Force notify Finder to refresh caches
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

// MARK: - Data HexString Helper
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            let bytes = hexString[index..<nextIndex]
            if let num = UInt8(bytes, radix: 16) {
                data.append(num)
            } else {
                return nil
            }
            index = nextIndex
        }
        self = data
    }
}

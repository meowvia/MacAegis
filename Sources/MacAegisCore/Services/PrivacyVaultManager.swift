import Foundation
import Darwin
import LocalAuthentication
import AppKit
import CryptoKit
import CommonCrypto

public enum VaultError: LocalizedError, Sendable {
    case keyDerivationFailed
    case fileNotFound(String)
    case authenticationRequired

    public var errorDescription: String? {
        switch self {
        case .keyDerivationFailed:
            return "主密码密钥派生失败，拒绝执行操作以防止弱混淆保护。"
        case .fileNotFound(let path):
            return "目标文件不存在：\(path)"
        case .authenticationRequired:
            return "尚未验证主密码或凭据已过期。"
        }
    }
}

public enum VaultItemType: String, Codable, Sendable {
    case hidden = "极速隐形"
    case concealed = "深度隐匿"
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
    public var sizeBytes: Int64
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
    public static let derivedKeyAccount = "derived_master_key"
    public static let metadataKeychainAccount = "master_metadata"
    public static let xattrVaultKey = "com.meowvia.macaegis.vault"

    private let metadataURL: URL
    private let authConfigURL: URL
    private let keychainService: String
    private let keychainAccount: String
    private let isTestIsolation: Bool
    private var items: [VaultItem] = []
    private var activeDEK: Data?
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

    // MARK: - Key Wrapping Cryptographic Engine (DEK + KEK via AES-GCM & PBKDF2)
    public static func wrapDEK(dek: Data, usingKEK kek: Data) -> (encryptedDEKHex: String, ivHex: String, tagHex: String)? {
        let symKey = SymmetricKey(data: kek)
        guard let sealed = try? AES.GCM.seal(dek, using: symKey) else { return nil }
        let encHex = sealed.ciphertext.map { String(format: "%02hhx", $0) }.joined()
        let ivHex = sealed.nonce.withUnsafeBytes { Data($0) }.map { String(format: "%02hhx", $0) }.joined()
        let tagHex = sealed.tag.map { String(format: "%02hhx", $0) }.joined()
        return (encHex, ivHex, tagHex)
    }

    public static func unwrapDEK(encryptedDEKHex: String, ivHex: String, tagHex: String, usingKEK kek: Data) -> Data? {
        guard let ct = Data(hexString: encryptedDEKHex),
              let iv = Data(hexString: ivHex),
              let tag = Data(hexString: tagHex),
              let nonce = try? AES.GCM.Nonce(data: iv) else { return nil }
        guard let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ct, tag: tag) else { return nil }
        let symKey = SymmetricKey(data: kek)
        return try? AES.GCM.open(sealedBox, using: symKey)
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
        if let data = try? Data(contentsOf: authConfigURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           json["salt"] != nil, json["hash"] != nil {
            return true
        }

        // 2. Fallback to macOS System Keychain (Immune to app uninstallation/cleanup)
        if !isTestIsolation,
           let keychainData = KeychainHelper.shared.load(service: keychainService, account: keychainAccount),
           let json = try? JSONSerialization.jsonObject(with: keychainData) as? [String: String],
           json["salt"] != nil, json["hash"] != nil {
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

        guard let kek = Self.deriveKeyPBKDF2(password: password, salt: saltData, iterations: 100_000) else {
            return false
        }

        // Generate permanent random 32-byte DEK (Data Encryption Key)
        var randomDEK = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomDEK.count, &randomDEK)
        let dekData = Data(randomDEK)

        guard let wrapped = Self.wrapDEK(dek: dekData, usingKEK: kek) else { return false }

        self.activeDEK = dekData
        self.activeDerivedKey = dekData
        self.activeSaltHex = saltHex

        let keyHash = kek.map { String(format: "%02hhx", $0) }.joined()

        let authData: [String: String] = [
            "salt": saltHex,
            "hash": keyHash,
            "hint": hint ?? "",
            "encrypted_dek": wrapped.encryptedDEKHex,
            "dek_iv": wrapped.ivHex,
            "dek_tag": wrapped.tagHex,
            "schema_version": "2"
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: authData, options: .prettyPrinted) else {
            return false
        }

        // 1. Save to local Application Support
        try? data.write(to: authConfigURL, options: .atomic)

        // 2. Save permanently to macOS System Keychain
        if !isTestIsolation {
            KeychainHelper.shared.save(service: keychainService, account: keychainAccount, data: data)
            KeychainHelper.shared.save(service: keychainService, account: Self.derivedKeyAccount, data: dekData)
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
              let kek = Self.deriveKeyPBKDF2(password: password, salt: saltData, iterations: 100_000) else {
            return false
        }

        let computedHash = kek.map { String(format: "%02hhx", $0) }.joined()
        if computedHash == expectedHash {
            // Decrypt DEK if wrapped format exists
            if let encDEK = json["encrypted_dek"], let iv = json["dek_iv"], let tag = json["dek_tag"] {
                if let dek = Self.unwrapDEK(encryptedDEKHex: encDEK, ivHex: iv, tagHex: tag, usingKEK: kek) {
                    self.activeDEK = dek
                    self.activeDerivedKey = dek
                }
            } else {
                // Fallback for legacy v1
                self.activeDEK = kek
                self.activeDerivedKey = kek
            }
            self.activeSaltHex = saltHex
            if !isTestIsolation {
                if let dek = self.activeDEK {
                    KeychainHelper.shared.save(service: keychainService, account: Self.derivedKeyAccount, data: dek)
                }
            }
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

    public func changeMasterPassword(oldPassword: String, newPassword: String, hint: String? = nil) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var authData = try? Data(contentsOf: authConfigURL)
        if authData == nil && !isTestIsolation {
            authData = KeychainHelper.shared.load(service: keychainService, account: keychainAccount)
        }

        guard let data = authData,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let oldSaltHex = json["salt"],
              let expectedHash = json["hash"],
              let oldSaltData = Data(hexString: oldSaltHex),
              let oldKEK = Self.deriveKeyPBKDF2(password: oldPassword, salt: oldSaltData, iterations: 100_000) else {
            return false
        }

        let computedHash = oldKEK.map { String(format: "%02hhx", $0) }.joined()
        guard computedHash == expectedHash else {
            return false
        }

        // 1. Decrypt current DEK using old KEK
        let currentDEK: Data
        if let encDEK = json["encrypted_dek"], let iv = json["dek_iv"], let tag = json["dek_tag"] {
            guard let dek = Self.unwrapDEK(encryptedDEKHex: encDEK, ivHex: iv, tagHex: tag, usingKEK: oldKEK) else {
                return false
            }
            currentDEK = dek
        } else {
            // Legacy upgrade: use activeDEK or oldKEK
            currentDEK = self.activeDEK ?? oldKEK
        }

        // 2. Generate new salt and new KEK
        var newSalt = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, newSalt.count, &newSalt)
        let newSaltData = Data(newSalt)
        let newSaltHex = newSaltData.map { String(format: "%02hhx", $0) }.joined()

        guard let newKEK = Self.deriveKeyPBKDF2(password: newPassword, salt: newSaltData, iterations: 100_000) else {
            return false
        }
        let newHashHex = newKEK.map { String(format: "%02hhx", $0) }.joined()

        // 3. Re-wrap the SAME DEK with the NEW KEK (Zero touches to locked files!)
        guard let wrapped = Self.wrapDEK(dek: currentDEK, usingKEK: newKEK) else { return false }

        var authDict: [String: String] = [
            "salt": newSaltHex,
            "hash": newHashHex,
            "encrypted_dek": wrapped.encryptedDEKHex,
            "dek_iv": wrapped.ivHex,
            "dek_tag": wrapped.tagHex,
            "schema_version": "2"
        ]
        if let h = hint, !h.isEmpty {
            authDict["hint"] = h
        } else if let oldHint = json["hint"], !oldHint.isEmpty {
            authDict["hint"] = oldHint
        }

        guard let newJsonData = try? JSONSerialization.data(withJSONObject: authDict, options: .prettyPrinted) else {
            return false
        }

        try? newJsonData.write(to: authConfigURL, options: .atomic)
        if !isTestIsolation {
            KeychainHelper.shared.save(service: keychainService, account: keychainAccount, data: newJsonData)
            KeychainHelper.shared.save(service: keychainService, account: Self.derivedKeyAccount, data: currentDEK)
        }

        self.activeDEK = currentDEK
        self.activeDerivedKey = currentDEK
        self.activeSaltHex = newSaltHex
        return true
    }

    public func resetMasterAuth(clearKeychain: Bool = true) {
        lock.lock()
        defer { lock.unlock() }

        // Automatically unlock and restore all currently locked files before destroying credentials!
        for item in items where item.status == .hidden {
            let url = URL(fileURLWithPath: item.path)
            _ = setFileHidden(at: url, hidden: false)
        }

        try? FileManager.default.removeItem(at: authConfigURL)
        try? "[]".write(to: metadataURL, atomically: true, encoding: .utf8)
        self.items = []
        self.activeDEK = nil
        self.activeDerivedKey = nil
        self.activeSaltHex = ""

        if clearKeychain && !isTestIsolation {
            KeychainHelper.shared.delete(service: keychainService, account: keychainAccount)
            KeychainHelper.shared.delete(service: keychainService, account: Self.derivedKeyAccount)
            KeychainHelper.shared.delete(service: keychainService, account: Self.metadataKeychainAccount)
        }
    }

    // MARK: - Biometric / Touch ID Authentication
    public func authenticateWithBiometrics(reason: String = "请验证 Touch ID 指纹以解锁隐私保险箱") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "使用密码"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                if success && !isTestIsolation {
                    if let key = KeychainHelper.shared.load(service: keychainService, account: Self.derivedKeyAccount) {
                        self.activeDerivedKey = key
                    }
                }
                return success
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
                let cPath = (path as NSString).fileSystemRepresentation
                _ = chflags(cPath, 0)
                chmod(path, 0o700)
                length = getxattr(path, Self.xattrVaultKey, nil, 0, 0, 0)
                if length > 0 {
                    var data = Data(count: length)
                    _ = data.withUnsafeMutableBytes { bytes in
                        getxattr(path, Self.xattrVaultKey, bytes.baseAddress, length, 0, 0)
                    }
                    chmod(path, originalMode)
                    _ = chflags(cPath, UInt32(UF_HIDDEN | UF_IMMUTABLE))
                    return String(data: data, encoding: .utf8)
                }
                chmod(path, originalMode)
                _ = chflags(cPath, UInt32(UF_HIDDEN | UF_IMMUTABLE))
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

        var metadataData = try? Data(contentsOf: metadataURL)
        if (metadataData == nil || metadataData?.isEmpty == true) && !isTestIsolation {
            metadataData = KeychainHelper.shared.load(service: keychainService, account: Self.metadataKeychainAccount)
            if let d = metadataData {
                try? d.write(to: metadataURL, options: .atomic)
            }
        }

        guard let data = metadataData,
              let loaded = try? JSONDecoder().decode([VaultItem].self, from: data) else {
            self.items = []
            return
        }

        var needsSave = false
        var updatedItems: [VaultItem] = []
        for var item in loaded {
            if item.sizeBytes == 0 {
                let realSize = calculateLockedItemSize(at: item.path)
                if realSize > 0 {
                    item.sizeBytes = realSize
                    needsSave = true
                }
            }
            updatedItems.append(item)
        }
        self.items = updatedItems
        if needsSave {
            if let encData = try? JSONEncoder().encode(self.items) {
                try? encData.write(to: metadataURL, options: .atomic)
                if !isTestIsolation {
                    KeychainHelper.shared.save(service: keychainService, account: Self.metadataKeychainAccount, data: encData)
                }
            }
        }
    }

    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: metadataURL, options: .atomic)
        if !isTestIsolation {
            KeychainHelper.shared.save(service: keychainService, account: Self.metadataKeychainAccount, data: data)
        }
    }

    public func fetchItems() -> [VaultItem] {
        lock.lock()
        defer { lock.unlock() }
        return items
    }

    /// Deep scans user home directories to auto-rescue any previously locked/hidden folders
    @discardableResult
    public func scanAndRecoverHiddenItems() -> [VaultItem] {
        lock.lock()
        defer { lock.unlock() }

        var recovered: [VaultItem] = []
        let fm = FileManager.default
        let home = NSHomeDirectory()
        var scanDirs = [
            home + "/Desktop",
            home + "/Documents",
            home + "/Downloads",
            home + "/Pictures",
            home + "/Movies",
            home
        ]

        if let volContents = try? fm.contentsOfDirectory(atPath: "/Volumes") {
            for volName in volContents {
                let vPath = "/Volumes/" + volName
                if vPath != "/Volumes/Macintosh HD" && !volName.hasPrefix(".") && !scanDirs.contains(vPath) {
                    scanDirs.append(vPath)
                }
            }
        }
        for dirPath in scanDirs {
            let dirURL = URL(fileURLWithPath: dirPath)
            guard let contents = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants]) else {
                continue
            }
            for url in contents {
                let path = url.path
                let name = url.lastPathComponent
                if name.hasPrefix(".") || name == "Library" || name == ".Trash" || name == ".git" {
                    continue
                }
                if items.contains(where: { $0.path == path }) {
                    continue
                }
                if isItemLockedOnDisk(at: url) || hasVaultXattr(at: path) {
                    let isExternal = path.hasPrefix("/Volumes/") && !path.hasPrefix("/Volumes/Macintosh HD")
                    let size = calculateLockedItemSize(at: path)
                    let item = VaultItem(
                        name: name,
                        path: path,
                        type: .hidden,
                        status: .hidden,
                        sizeBytes: size,
                        isExternalDrive: isExternal
                    )
                    items.append(item)
                    recovered.append(item)
                }
            }
        }

        if !recovered.isEmpty {
            if let data = try? JSONEncoder().encode(items) {
                try? data.write(to: metadataURL, options: .atomic)
                if !isTestIsolation {
                    KeychainHelper.shared.save(service: keychainService, account: Self.metadataKeychainAccount, data: data)
                }
            }
        }
        return recovered
    }

    // MARK: - Core Operations & Disaster Re-claiming
    public func addItem(url: URL, type: VaultItemType) -> VaultItem? {
        lock.lock()
        defer { lock.unlock() }

        let path = url.path
        if let existing = items.first(where: { $0.path == path }) {
            return existing
        }

        let isExternal = path.hasPrefix("/Volumes/") && !path.hasPrefix("/Volumes/Macintosh HD")
        let name = url.lastPathComponent

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)

        // Calculate accurate size BEFORE locking so directory traversal succeeds
        var calculatedSize: Int64 = FileUtils.calculateSize(atPath: path)
        let isAlreadyLocked = isItemLockedOnDisk(at: url)

        if calculatedSize == 0 && isAlreadyLocked {
            calculatedSize = calculateLockedItemSize(at: path)
        }

        if !isAlreadyLocked {
            // Fresh un-locked item: Lock/Hide immediately (Instant Darwin syscall)
            let success = setFileHidden(at: url, hidden: true)
            if !success {
                return nil
            }
        }

        let item = VaultItem(
            name: name,
            path: path,
            type: type,
            status: .hidden,
            sizeBytes: calculatedSize,
            isExternalDrive: isExternal
        )

        items.append(item)
        saveMetadata()
        return item
    }

    private func calculateLockedItemSize(at path: String) -> Int64 {
        var statBuf = stat()
        guard lstat(path, &statBuf) == 0 else { return 0 }
        let originalMode = statBuf.st_mode
        let cPath = (path as NSString).fileSystemRepresentation
        _ = chflags(cPath, 0)
        chmod(path, 0o755)
        let size = FileUtils.calculateSize(atPath: path)
        chmod(path, originalMode)
        _ = chflags(cPath, UInt32(UF_HIDDEN | UF_IMMUTABLE))
        return size
    }

    public func updateItemSize(path: String, size: Int64) {
        lock.lock()
        defer { lock.unlock() }
        if let index = items.firstIndex(where: { $0.path == path }) {
            items[index].sizeBytes = size
            saveMetadata()
        }
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

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let url = URL(fileURLWithPath: items[index].path)
            let success = setFileHidden(at: url, hidden: false)
            if success {
                items[index].status = .visible
                saveMetadata()
            }
        }
    }

    public func lockItem(item: VaultItem) {
        lock.lock()
        defer { lock.unlock() }

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let url = URL(fileURLWithPath: items[index].path)
            let success = setFileHidden(at: url, hidden: true)
            if success {
                items[index].status = .hidden
                saveMetadata()
            }
        }
    }

    public func lockAll() {
        lock.lock()
        defer { lock.unlock() }

        for i in 0..<items.count {
            let url = URL(fileURLWithPath: items[i].path)
            let success = setFileHidden(at: url, hidden: true)
            if success {
                items[i].status = .hidden
            }
        }
        saveMetadata()
    }

    public func toggleHidden(item: VaultItem, revealInFinder: Bool = true) -> VaultItemStatus {
        lock.lock()
        defer { lock.unlock() }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return item.status }
        let url = URL(fileURLWithPath: items[index].path)
        let willHide = items[index].status != .hidden

        let success = setFileHidden(at: url, hidden: willHide)
        if !success {
            return items[index].status
        }
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
            _ = setFileHidden(at: URL(fileURLWithPath: item.path), hidden: false)
            items.remove(at: index)
            saveMetadata()
        }
    }

    // MARK: - Direct Finder Navigation
    public func openAndHighlightInFinder(path: String, revealInFinder: Bool = true) {
        let expanded = FileUtils.expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }

        let url = URL(fileURLWithPath: expanded)
        _ = setFileHidden(at: url, hidden: false)
        if revealInFinder {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    // MARK: - In-Place 4KB Dynamic DEK Key-Derived Header Stream Obfuscation (Fast-Fail)
    private func transformHeader(at fileURL: URL, derivedKey: Data?) throws {
        guard let derivedKey = derivedKey, !derivedKey.isEmpty else {
            // Fast-Fail: 拒绝降级为弱混淆，抛出错误中止
            throw VaultError.keyDerivationFailed
        }
        guard let handle = try? FileHandle(forUpdating: fileURL) else { return }
        defer { try? handle.close() }

        guard let headerData = try? handle.read(upToCount: 4096), !headerData.isEmpty else { return }
        var bytes = [UInt8](headerData)
        let keyBytes = [UInt8](derivedKey)
        let keyLen = keyBytes.count

        for i in 0..<bytes.count {
            let mask = keyBytes[i % keyLen]
            bytes[i] ^= mask
        }
        let transformed = Data(bytes)
        try? handle.seek(toOffset: 0)
        try? handle.write(contentsOf: transformed)
    }

    private func applyHeaderTransformation(at url: URL) throws {
        let key = activeDEK ?? activeDerivedKey
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                try transformHeader(at: url, derivedKey: key)
            }
        }
    }

    @discardableResult
    private func setFileHidden(at url: URL, hidden: Bool) -> Bool {
        let path = url.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return false }

        // Auto-recover activeDEK / activeDerivedKey from Keychain if needed
        if activeDEK == nil && activeDerivedKey == nil && !isTestIsolation {
            if let key = KeychainHelper.shared.load(service: keychainService, account: Self.derivedKeyAccount) {
                self.activeDEK = key
                self.activeDerivedKey = key
            }
        }

        let cPath = (path as NSString).fileSystemRepresentation

        if hidden {
            // 1. In-place 4KB header transformation for single file (Fast-Fail)
            do {
                try applyHeaderTransformation(at: url)
            } catch {
                return false
            }

            // 2. Mark native macOS Extended Attribute (xattr) BEFORE changing permissions
            let salt = activeSaltHex.isEmpty ? "MacAegisLocked" : activeSaltHex
            setVaultXattr(at: path, saltHex: salt)

            // 3. Darwin C syscall: clear uchg, set POSIX 000, set uchg + hidden (0.03ms instant)
            _ = chflags(cPath, 0)
            let perms: NSNumber = 0o000
            try? FileManager.default.setAttributes([.posixPermissions: perms], ofItemAtPath: path)
            _ = chflags(cPath, UInt32(UF_HIDDEN | UF_IMMUTABLE))

            var resourceValues = URLResourceValues()
            resourceValues.isHidden = true
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)
        } else {
            // Defensive Unlocking Order:
            // 1. First temporarily clear immutable flag and grant read-write permission for restoration
            _ = chflags(cPath, 0)
            let tempPerms: NSNumber = isDir.boolValue ? 0o700 : 0o600
            try? FileManager.default.setAttributes([.posixPermissions: tempPerms], ofItemAtPath: path)

            // 2. Reverse header transformation to restore exact original binary signature BEFORE removing lock markers!
            do {
                try applyHeaderTransformation(at: url)
            } catch {
                // Restoration failed: Immediately re-lock item and abort to prevent data corruption!
                let lockPerms: NSNumber = 0o000
                try? FileManager.default.setAttributes([.posixPermissions: lockPerms], ofItemAtPath: path)
                _ = chflags(cPath, UInt32(UF_HIDDEN | UF_IMMUTABLE))
                return false
            }

            // 3. Header successfully restored: Now reset standard POSIX permissions and remove xattr
            let perms: NSNumber = isDir.boolValue ? 0o755 : 0o644
            try? FileManager.default.setAttributes([.posixPermissions: perms], ofItemAtPath: path)
            removeVaultXattr(at: path)

            var resourceValues = URLResourceValues()
            resourceValues.isHidden = false
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)
        }

        // 4. Notify Finder to refresh caches
        NSWorkspace.shared.noteFileSystemChanged(path)
        let parentPath = url.deletingLastPathComponent().path
        NSWorkspace.shared.noteFileSystemChanged(parentPath)
        return true
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

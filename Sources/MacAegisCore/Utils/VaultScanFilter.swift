import Foundation

/// Protocol for filtering locked or concealed privacy paths during scanning and cleaning.
public protocol VaultScanFilterProtocol: Sendable {
    func isLockedForScanSkip(path: String) -> Bool
}

/// Fallback null filter used when the proprietary Privacy Vault module is not active or in open-source builds.
public struct NullVaultScanFilter: VaultScanFilterProtocol, Sendable {
    public init() {}
    public func isLockedForScanSkip(path: String) -> Bool {
        return false
    }
}

/// Thread-safe registry for the active vault scan filter.
public final class VaultFilterRegistry: @unchecked Sendable {
    public static let shared = VaultFilterRegistry()

    private let lock = NSLock()
    private var filter: any VaultScanFilterProtocol = NullVaultScanFilter()

    public init() {}

    public var currentFilter: any VaultScanFilterProtocol {
        lock.lock()
        defer { lock.unlock() }
        return filter
    }

    public func register(filter: any VaultScanFilterProtocol) {
        lock.lock()
        defer { lock.unlock() }
        self.filter = filter
    }
}

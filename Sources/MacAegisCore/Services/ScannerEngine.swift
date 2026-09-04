import Foundation

public final class ScannerEngine: Sendable {
    public let rules: [any CleanRuleProtocol]

    public init(rules: [any CleanRuleProtocol]? = nil) {
        if let customRules = rules {
            self.rules = customRules
        } else {
            self.rules = [
                MessagingRules(),
                DeveloperRules(),
                BrowserRules(),
                DownloadsRules(),
                AppCacheRules(),
                SystemCacheRules(),
                CreativeProjectRules(),
                GamingJunkRules(),
                OrphanHunterRules(),
                LargeFileRules(),
                ExternalDriveRules()
            ]
        }
    }

    /// Perform a full system and app scan in parallel (Thread-safe onFoundItem dispatch with strict privacy anti-leak filtering)
    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)? = nil) async -> ScanResult {
        let startTime = Date()
        let privacyVault = PrivacyVaultManager.shared

        // Force fresh indexing of installed applications to accurately identify live apps and orphans
        _ = AppDetector.shared.indexInstalledApps(forceRefresh: true)

        let threadSafeCallback: (@Sendable (CleanItem) -> Void)?
        if let originalCallback = onFoundItem {
            let callbackLock = NSLock()
            threadSafeCallback = { item in
                // Anti-Leak Hard Constraint: Drop any items locked or managed by Privacy Conceal
                if !privacyVault.isLockedForScanSkip(path: item.path) {
                    callbackLock.lock()
                    defer { callbackLock.unlock() }
                    originalCallback(item)
                }
            }
        } else {
            threadSafeCallback = nil
        }

        let allItems = await withTaskGroup(of: [CleanItem].self, returning: [CleanItem].self) { group in
            for rule in rules {
                group.addTask {
                    await rule.scan(onFoundItem: threadSafeCallback)
                }
            }

            var combined: [CleanItem] = []
            for await items in group {
                combined.append(contentsOf: items)
            }
            return combined
        }

        // Apply strict Privacy Conceal anti-leak hard filter and eliminate 0-byte items
                let hasFDA = FileManager.default.isReadableFile(atPath: NSHomeDirectory() + "/Library/Safari/Bookmarks.plist")
        var safeItems = allItems.filter { item in
            guard !privacyVault.isLockedForScanSkip(path: item.path) && item.sizeBytes > 0 else { return false }
            
            // If it's a Sandbox Container and we don't have FDA, we CANNOT delete it silently.
            // Filter it out to prevent false promises and annoying error modals.
            if item.path.contains("Library/Containers") && !hasFDA {
                return false
            }
            return true
        }

        // Strict 0-9, A-Z natural deterministic sorting (cannot be manually overridden)
        safeItems.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let duration = Date().timeIntervalSince(startTime)
        return ScanResult(items: safeItems, durationSeconds: duration)
    }
}

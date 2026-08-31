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
                OrphanHunterRules(),
                LargeFileRules()
            ]
        }
    }

    /// Perform a full system and app scan in parallel (Thread-safe onFoundItem dispatch)
    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)? = nil) async -> ScanResult {
        let startTime = Date()

        // Force fresh indexing of installed applications to accurately identify live apps and orphans
        _ = AppDetector.shared.indexInstalledApps(forceRefresh: true)

        let threadSafeCallback: (@Sendable (CleanItem) -> Void)?
        if let originalCallback = onFoundItem {
            let callbackLock = NSLock()
            threadSafeCallback = { item in
                callbackLock.lock()
                defer { callbackLock.unlock() }
                originalCallback(item)
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

        var sortedItems = allItems
        // Strict 0-9, A-Z natural deterministic sorting (cannot be manually overridden)
        sortedItems.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let duration = Date().timeIntervalSince(startTime)
        return ScanResult(items: sortedItems, durationSeconds: duration)
    }
}

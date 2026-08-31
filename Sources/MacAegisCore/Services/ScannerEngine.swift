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

    /// Perform a full system and app scan in parallel
    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)? = nil) async -> ScanResult {
        let startTime = Date()

        let allItems = await withTaskGroup(of: [CleanItem].self, returning: [CleanItem].self) { group in
            for rule in rules {
                group.addTask {
                    await rule.scan(onFoundItem: onFoundItem)
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

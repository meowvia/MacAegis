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
                OrphanHunterRules()
            ]
        }
    }

    /// Perform a full system and app scan
    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)? = nil) async -> ScanResult {
        let startTime = Date()
        var allItems: [CleanItem] = []

        for rule in rules {
            let items = await rule.scan(onFoundItem: onFoundItem)
            allItems.append(contentsOf: items)
        }

        // Strict 0-9, A-Z natural deterministic sorting (cannot be manually overridden)
        allItems.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let duration = Date().timeIntervalSince(startTime)
        return ScanResult(items: allItems, durationSeconds: duration)
    }
}

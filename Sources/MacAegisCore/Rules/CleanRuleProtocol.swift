import Foundation

public protocol CleanRuleProtocol: Sendable {
    var ruleId: String { get }
    var displayName: String { get }
    var category: CleanCategory { get }
    func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem]
}

import Foundation

public enum SafetyLevel: String, Codable, Sendable {
    /// Safe to delete; system or apps will recreate automatically without data loss
    case safe
    /// Contains cached downloads, chat media previews, or workspace build caches. Review recommended.
    case caution
    /// Sensitive user data; only delete if absolutely certain
    case danger

    public var title: String {
        switch self {
        case .safe: return "无感安全"
        case .caution: return "建议核对"
        case .danger: return "谨慎删除"
        }
    }

    public var badge: String {
        switch self {
        case .safe: return "🟢"
        case .caution: return "🟡"
        case .danger: return "🔴"
        }
    }
}

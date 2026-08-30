import Foundation

public struct ByteFormatter: Sendable {
    public static func format(_ bytes: Int64) -> String {
        if bytes <= 0 {
            return "0 KB"
        }
        let formatted = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        if formatted.caseInsensitiveCompare("Zero KB") == .orderedSame || formatted.caseInsensitiveCompare("Zero bytes") == .orderedSame {
            return "0 KB"
        }
        return formatted
    }
}

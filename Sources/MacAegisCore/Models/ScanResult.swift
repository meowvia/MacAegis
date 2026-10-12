import Foundation

public struct ScanResult: Sendable {
    public let items: [CleanItem]
    public let durationSeconds: Double

    public init(items: [CleanItem], durationSeconds: Double = 0.0) {
        self.items = items
        self.durationSeconds = durationSeconds
    }

    public var totalSizeBytes: Int64 {
        return items.reduce(0) { $0 + $1.sizeBytes }
    }

    public var totalFormattedSize: String {
        return ByteFormatter.format(totalSizeBytes)
    }

    public var safeSizeBytes: Int64 {
        return items.filter { $0.safetyLevel == .safe }.reduce(0) { $0 + $1.sizeBytes }
    }

    public var safeFormattedSize: String {
        return ByteFormatter.format(safeSizeBytes)
    }

    public func items(for category: CleanCategory) -> [CleanItem] {
        return items.filter { $0.category == category }
    }

    public func totalSize(for category: CleanCategory) -> Int64 {
        return items(for: category).reduce(0) { $0 + $1.sizeBytes }
    }
}

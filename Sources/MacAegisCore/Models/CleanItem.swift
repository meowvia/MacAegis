import Foundation

public struct CleanItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let sizeBytes: Int64
    public let category: CleanCategory
    public let safetyLevel: SafetyLevel
    public let itemDescription: String
    public let associatedAppName: String?
    public var isSelected: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        sizeBytes: Int64,
        category: CleanCategory,
        safetyLevel: SafetyLevel,
        itemDescription: String,
        associatedAppName: String? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.category = category
        self.safetyLevel = safetyLevel
        self.itemDescription = itemDescription
        self.associatedAppName = associatedAppName
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        return ByteFormatter.format(sizeBytes)
    }
}

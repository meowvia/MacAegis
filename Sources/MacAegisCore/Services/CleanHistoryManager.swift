import Foundation

public struct CleanHistoryRecord: Identifiable, Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let totalReclaimedBytes: Int64
    public let itemCount: Int
    public let useTrash: Bool
    public let cleanedPaths: [String]

    public var formattedReclaimed: String {
        return ByteFormatter.format(totalReclaimedBytes)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        totalReclaimedBytes: Int64,
        itemCount: Int,
        useTrash: Bool,
        cleanedPaths: [String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalReclaimedBytes = totalReclaimedBytes
        self.itemCount = itemCount
        self.useTrash = useTrash
        self.cleanedPaths = cleanedPaths
    }
}

public final class CleanHistoryManager: @unchecked Sendable {
    public static let shared = CleanHistoryManager()

    private let historyFileURL: URL
    private var records: [CleanHistoryRecord] = []
    private let lock = NSLock()

    public init(customFileURL: URL? = nil) {
        if let custom = customFileURL {
            self.historyFileURL = custom
        } else {
            let path = FileUtils.expandPath("~/Library/Application Support/MacAegis/clean_history.json")
            self.historyFileURL = URL(fileURLWithPath: path)
        }
        loadHistory()
    }

    private func loadHistory() {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: historyFileURL),
              let list = try? JSONDecoder().decode([CleanHistoryRecord].self, from: data) else {
            records = []
            return
        }
        records = list
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: historyFileURL, options: .atomic)
    }

    public func recordClean(reclaimedBytes: Int64, itemCount: Int, useTrash: Bool, cleanedPaths: [String]) {
        lock.lock()
        defer { lock.unlock() }

        let record = CleanHistoryRecord(
            totalReclaimedBytes: reclaimedBytes,
            itemCount: itemCount,
            useTrash: useTrash,
            cleanedPaths: cleanedPaths
        )
        records.insert(record, at: 0)
        // Keep last 100 records
        if records.count > 100 {
            records = Array(records.prefix(100))
        }
        saveHistory()
    }

    public func fetchHistory() -> [CleanHistoryRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }

    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        records = []
        saveHistory()
    }
}

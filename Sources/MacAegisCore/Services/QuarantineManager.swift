import Foundation

public struct QuarantinedItem: Identifiable, Codable, Sendable {
    public let id: String
    public let originalPath: String
    public let quarantinedPath: String
    public let appName: String
    public let sizeBytes: Int64
    public let quarantinedDate: Date
    public let bundleId: String?

    public init(
        id: String = UUID().uuidString,
        originalPath: String,
        quarantinedPath: String,
        appName: String,
        sizeBytes: Int64,
        quarantinedDate: Date = Date(),
        bundleId: String? = nil
    ) {
        self.id = id
        self.originalPath = originalPath
        self.quarantinedPath = quarantinedPath
        self.appName = appName
        self.sizeBytes = sizeBytes
        self.quarantinedDate = quarantinedDate
        self.bundleId = bundleId
    }
}

public final class QuarantineManager: @unchecked Sendable {
    public static let shared = QuarantineManager()

    private let fileManager = FileManager.default
    private let lock = NSLock()
    private let defaultBaseDir: URL?

    public init(customBaseDirectory: URL? = nil) {
        self.defaultBaseDir = customBaseDirectory
    }

    /// Determine volume-aware quarantine root directory
    public func quarantineRoot(for path: String) -> URL {
        if let custom = defaultBaseDir {
            return custom
        }

        // External drive volume-aware detection: keep on same volume for atomic microsecond rename
        if path.hasPrefix("/Volumes/") {
            let components = path.split(separator: "/")
            if components.count >= 2 {
                let volumePath = "/Volumes/\(components[1])"
                let candidate = URL(fileURLWithPath: volumePath).appendingPathComponent(".MacAegisQuarantine")
                if (try? fileManager.createDirectory(at: candidate, withIntermediateDirectories: true)) != nil {
                    return candidate
                }
            }
        }

        // Main system drive fallback
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let systemQuarantine = appSupport.appendingPathComponent("MacAegis/Quarantine", isDirectory: true)
        try? fileManager.createDirectory(at: systemQuarantine, withIntermediateDirectories: true)
        return systemQuarantine
    }

    /// Move item to volume-aware quarantine
    @discardableResult
    public func quarantine(itemPath: String, appName: String, bundleId: String? = nil) throws -> QuarantinedItem {
        lock.lock()
        defer { lock.unlock() }

        guard fileManager.fileExists(atPath: itemPath) else {
            throw NSError(domain: "QuarantineManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item does not exist"])
        }

        let size = FileUtils.calculateSize(atPath: itemPath)
        let root = quarantineRoot(for: itemPath)
        let itemId = UUID().uuidString
        let destContainer = root.appendingPathComponent(itemId, isDirectory: true)
        try fileManager.createDirectory(at: destContainer, withIntermediateDirectories: true)

        let itemName = URL(fileURLWithPath: itemPath).lastPathComponent
        let destItemURL = destContainer.appendingPathComponent(itemName)

        // Same-volume atomic move: 0-copy, microsecond speed
        try fileManager.moveItem(at: URL(fileURLWithPath: itemPath), to: destItemURL)

        let record = QuarantinedItem(
            id: itemId,
            originalPath: itemPath,
            quarantinedPath: destItemURL.path,
            appName: appName,
            sizeBytes: size,
            quarantinedDate: Date(),
            bundleId: bundleId
        )

        let metaURL = destContainer.appendingPathComponent("meta.json")
        if let data = try? JSONEncoder().encode(record) {
            try? data.write(to: metaURL, options: .atomic)
        }

        return record
    }

    /// 1-Click Restore item back to its original path
    public func restore(item: QuarantinedItem) throws {
        lock.lock()
        defer { lock.unlock() }

        let originalURL = URL(fileURLWithPath: item.originalPath)
        let parentDir = originalURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: item.originalPath) {
            throw NSError(domain: "QuarantineManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Original path already occupied"])
        }

        // Atomic move back to original location
        try fileManager.moveItem(at: URL(fileURLWithPath: item.quarantinedPath), to: originalURL)

        // Remove container and metadata
        let container = URL(fileURLWithPath: item.quarantinedPath).deletingLastPathComponent()
        try? fileManager.removeItem(at: container)
    }

    /// Purge expired quarantined items older than given days (default 7 days)
    @discardableResult
    public func purgeExpired(days: Int = 7) -> Int {
        lock.lock()
        defer { lock.unlock() }

        let expirationDate = Date().addingTimeInterval(-Double(days * 86400))
        var purgedCount = 0

        var rootsToInspect: [URL] = []
        if let custom = defaultBaseDir {
            rootsToInspect.append(custom)
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            rootsToInspect.append(appSupport.appendingPathComponent("MacAegis/Quarantine", isDirectory: true))
            // Check mounted volumes
            if let volContents = try? fileManager.contentsOfDirectory(atPath: "/Volumes") {
                for vol in volContents {
                    let candidate = URL(fileURLWithPath: "/Volumes/\(vol)/.MacAegisQuarantine")
                    if fileManager.fileExists(atPath: candidate.path) {
                        rootsToInspect.append(candidate)
                    }
                }
            }
        }

        for root in rootsToInspect {
            guard let containers = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                continue
            }
            for container in containers {
                let metaURL = container.appendingPathComponent("meta.json")
                if let data = try? Data(contentsOf: metaURL),
                   let record = try? JSONDecoder().decode(QuarantinedItem.self, from: data) {
                    if record.quarantinedDate < expirationDate {
                        try? fileManager.removeItem(at: container)
                        purgedCount += 1
                    }
                }
            }
        }
        return purgedCount
    }
}

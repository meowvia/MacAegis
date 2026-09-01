import Foundation

public struct MountedDriveInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let mountPath: String
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let isInternal: Bool
    public let isRemovable: Bool

    public var usedBytes: Int64 {
        return max(0, totalBytes - freeBytes)
    }

    public var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }

    public var formattedTotal: String {
        return ByteFormatter.format(totalBytes)
    }

    public var formattedUsed: String {
        return ByteFormatter.format(usedBytes)
    }

    public var formattedFree: String {
        return ByteFormatter.format(freeBytes)
    }

    public var icon: String {
        if isInternal {
            return "internaldrive.fill"
        } else {
            return "externaldrive.fill"
        }
    }
}

public final class DiskDetector: Sendable {
    public static let shared = DiskDetector()

    public init() {}

    /// Enumerate all mounted internal and external storage devices (Instant O(1) non-blocking)
    public func fetchMountedDrives() -> [MountedDriveInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey
        ]

        guard let volumeURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }

        var drives: [MountedDriveInfo] = []

        for url in volumeURLs {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let name = values.volumeName ?? url.lastPathComponent
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
            let isInternal = values.volumeIsInternal ?? false
            let isRemovable = (values.volumeIsRemovable ?? false) || (values.volumeIsEjectable ?? false)

            // Skip zero capacity or virtual recovery volumes
            guard total > 0, !name.hasPrefix("com.apple.") else { continue }

            drives.append(MountedDriveInfo(
                id: url.path,
                name: name,
                mountPath: url.path,
                totalBytes: total,
                freeBytes: free,
                isInternal: isInternal,
                isRemovable: isRemovable
            ))
        }

        // Sort: Internal drives first, then alphabetical
        return drives.sorted {
            if $0.isInternal != $1.isInternal {
                return $0.isInternal && !$1.isInternal
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

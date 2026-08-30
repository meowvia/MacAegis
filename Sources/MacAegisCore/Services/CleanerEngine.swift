import Foundation

public struct CleanExecutionReport: Sendable {
    public let successfulCount: Int
    public let failedCount: Int
    public let totalReclaimedBytes: Int64
    public let isDryRun: Bool
    public let errors: [String]

    public var formattedReclaimed: String {
        return ByteFormatter.format(totalReclaimedBytes)
    }
}

public final class CleanerEngine: Sendable {
    public init() {}

    /// Execute cleaning on given items with strict multi-layer whitelist protection
    public func clean(
        items: [CleanItem],
        dryRun: Bool = false,
        useTrash: Bool = true,
        onProgress: (@Sendable (CleanItem, Bool, String?) -> Void)? = nil
    ) -> CleanExecutionReport {
        var successCount = 0
        var failCount = 0
        var reclaimedBytes: Int64 = 0
        var errors: [String] = []
        let whitelist = WhitelistManager.shared

        for item in items where item.isSelected {
            // Absolute Safety Check: Abort if path is protected or dangerous
            if whitelist.isProtected(path: item.path) {
                failCount += 1
                let errStr = "【安全拦截】\(item.name) 包含系统关键数据或受保护文件，已拒绝清理"
                errors.append(errStr)
                onProgress?(item, false, errStr)
                continue
            }

            if dryRun {
                successCount += 1
                reclaimedBytes += item.sizeBytes
                onProgress?(item, true, nil)
                continue
            }

            do {
                if useTrash {
                    try FileUtils.moveToTrash(path: item.path)
                } else {
                    try FileUtils.removePermanently(path: item.path)
                }
                successCount += 1
                reclaimedBytes += item.sizeBytes
                onProgress?(item, true, nil)
            } catch {
                failCount += 1
                let errStr = "无法清理 \(item.name) (\(item.path)): \(error.localizedDescription)"
                errors.append(errStr)
                onProgress?(item, false, errStr)
            }
        }

        return CleanExecutionReport(
            successfulCount: successCount,
            failedCount: failCount,
            totalReclaimedBytes: reclaimedBytes,
            isDryRun: dryRun,
            errors: errors
        )
    }
}

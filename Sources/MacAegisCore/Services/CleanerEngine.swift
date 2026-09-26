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
    ) async -> CleanExecutionReport {
        var successCount = 0
        var failCount = 0
        var reclaimedBytes: Int64 = 0
        var errors: [String] = []
        let whitelist = WhitelistManager.shared

        var actuallyCleanedPaths: [String] = []

        for item in items where item.isSelected {
            let isCacheCategory: Bool = {
                switch item.category {
                case .browserCaches, .appCaches, .messagingMedia, .developerCaches, .systemCaches, .systemLogs:
                    return true
                case .downloadsAndPackages, .orphanLeftovers, .largeFiles:
                    return false
                }
            }()
            let protectionMode: ProtectionMode = isCacheCategory ? .cacheOnly : .strict

            // Absolute Safety Check: Abort if path is protected or dangerous
            if whitelist.isProtected(path: item.path, mode: protectionMode) {
                failCount += 1
                let errStr = l10n("【安全拦截】\(item.name) 包含系统关键数据或受保护文件，已拒绝清理", "[Protected] \(item.name) contains critical system data or is protected by safety whitelist.")
                errors.append(errStr)
                onProgress?(item, false, errStr)
                continue
            }

            // Privacy Conceal Absolute Protection Check: Block deletion of any locked/managed vault items
            if PrivacyVaultManager.shared.isLockedForScanSkip(path: item.path) {
                failCount += 1
                let errStr = l10n("【独立空间保护】\(item.name) 正处于独立空间保护中，已拒绝清理", "[Protected] \(item.name) is currently protected in Private Space.")
                errors.append(errStr)
                onProgress?(item, false, errStr)
                continue
            }

            if dryRun {
                successCount += 1
                reclaimedBytes += item.sizeBytes
                actuallyCleanedPaths.append(item.path)
                onProgress?(item, true, nil)
                continue
            }

            // Privilege Escalation Prevention: Never invoke dialog-prompting operations on system/root items
            if useTrash && !FileUtils.canTrashWithoutPrivilegeEscalation(path: item.path) {
                if isCacheCategory {
                    let internalReclaimed = FileUtils.emptyDirectoryContents(atPath: item.path)
                    if internalReclaimed > 0 {
                        successCount += 1
                        reclaimedBytes += internalReclaimed
                        actuallyCleanedPaths.append(item.path)
                        onProgress?(item, true, nil)
                        continue
                    }
                }

                if !FileManager.default.isDeletableFile(atPath: item.path) {
                    // Graceful Degradation: Silently skip undeletable protected items without polluting user report
                    failCount += 1
                    continue
                }
            }

            do {
                if useTrash {
                    try await FileUtils.moveToTrash(path: item.path)
                } else {
                    try FileManager.default.removeItem(atPath: item.path)
                }
                
                let isSnapshotPath = item.path.hasSuffix("com.apple.TimeMachine.Snapshots")
                if isSnapshotPath || !FileManager.default.fileExists(atPath: item.path) {
                    successCount += 1
                    reclaimedBytes += item.sizeBytes
                    actuallyCleanedPaths.append(item.path)
                    onProgress?(item, true, nil)
                } else {
                    failCount += 1
                    let errStr = l10n("【未生效】\(item.name) 清理后仍存在于原位", "[Ineffective] \(item.name) still exists")
                    errors.append(errStr)
                    onProgress?(item, false, errStr)
                }
            } catch {
                // Fallback: If deleting the entire cache folder failed (e.g. running browser holding an open socket/lock),
                if isCacheCategory {
                    let internalReclaimed = FileUtils.emptyDirectoryContents(atPath: item.path)
                    if internalReclaimed > 0 {
                        successCount += 1
                        reclaimedBytes += internalReclaimed
                        actuallyCleanedPaths.append(item.path)
                        onProgress?(item, true, nil)
                        continue
                    }
                }

                let errDesc = error.localizedDescription.lowercased()
                if errDesc.contains("permission") || errDesc.contains("not permitted") || errDesc.contains("denied") || (error as? CocoaError)?.code == .fileWriteNoPermission || (error as? CocoaError)?.code == .fileReadNoPermission {
                    let hasFDA = FullDiskAccessHelper.shared.hasFullDiskAccess()
                    failCount += 1
                    let userFriendlyReason: String
                    if !hasFDA {
                        userFriendlyReason = l10n("【需完全磁盘访问权限】清理「\(item.name)」受 macOS 沙盒保护拦截。请前往“系统设置 > 隐私与安全性 > 完全磁盘访问权限”授予 MacAegis 权限后重试。", 
                        "[Full Disk Access Required] Cleaning '\(item.name)' was blocked by macOS sandbox. Please grant Full Disk Access to MacAegis in System Settings > Privacy & Security.")
                    } else {
                        userFriendlyReason = l10n("【受系统文件保护】「\(item.name)」受 macOS 系统底层保护或已被系统锁定，已自动安全跳过。",
                        "[System Protected] '\(item.name)' is protected or locked by macOS, safely skipped.")
                    }
                    errors.append(userFriendlyReason)
                    onProgress?(item, false, userFriendlyReason)
                    continue
                }

                failCount += 1
                let userFriendlyReason = CleanerEngine.localizedErrorMessage(for: error, itemName: item.name, path: item.path)
                errors.append(userFriendlyReason)
                onProgress?(item, false, userFriendlyReason)
            }
        }

        if !dryRun && successCount > 0 {
            CleanHistoryManager.shared.recordClean(
                reclaimedBytes: reclaimedBytes,
                itemCount: successCount,
                useTrash: useTrash,
                cleanedPaths: actuallyCleanedPaths
            )
        }

        return CleanExecutionReport(
            successfulCount: successCount,
            failedCount: failCount,
            totalReclaimedBytes: reclaimedBytes,
            isDryRun: dryRun,
            errors: errors
        )
    }

    public static func localizedErrorMessage(for error: Error, itemName: String, path: String? = nil) -> String {
        let nsError = error as NSError
        let desc = error.localizedDescription.lowercased()
        let resolvedPath = path ?? ""

        // 1. User cancellation of authentication dialog
        if nsError.code == -128 || desc.contains("canceled") || desc.contains("cancelled") || desc.contains("取消") {
            return l10n("【授权取消】\(itemName) 未获得管理员授权，已跳过卸载", "[Cancelled] Administrator authorization cancelled for \(itemName), skipped.")
        }

        // 2. Cocoa Error Domain
        if let cocoaErr = error as? CocoaError {
            if cocoaErr.code == .fileWriteNoPermission || cocoaErr.code == .fileReadNoPermission {
                if itemName.hasSuffix(".app") {
                    return l10n("【需要授权】\(itemName) 为受系统保护的应用，需管理员权限或在“系统设置 > 隐私与安全性 > App 管理”中授权",
                                "[Authorization Required] \(itemName) is protected. Administrator privileges or App Management permission is required.")
                }
                return l10n("【权限不足】\(itemName) 无法访问，请在“系统设置 > 隐私与安全性 > 完全磁盘访问权限”中授权 MacAegis",
                            "[Access Denied] Cannot access \(itemName). Please grant Full Disk Access in System Settings > Privacy & Security.")
            }
            if cocoaErr.code == .fileWriteVolumeReadOnly {
                return l10n("【磁盘只读】\(itemName) 所在磁盘为只读状态，无法修改或删除",
                            "[Read-Only] Disk containing \(itemName) is read-only.")
            }
        }

        // 3. Busy / Locked by running process
        if desc.contains("busy") || desc.contains("resource busy") || desc.contains("in use") || desc.contains("locked") {
            return l10n("【软件占用】\(itemName) 正被运行中的应用程序锁定，请先完全退出相关程序后重试",
                        "[In Use] \(itemName) is locked by a running application. Please quit the application and retry.")
        }

        // 4. SIP vs TCC
        if desc.contains("operation not permitted") || desc.contains("sip") || desc.contains("integrity") {
            if resolvedPath.hasPrefix("/System/") || resolvedPath.hasPrefix("/usr/") || resolvedPath.hasPrefix("/bin/") || resolvedPath.hasPrefix("/sbin/") {
                return l10n("【系统保护】\(itemName) 受到 macOS 系统完整性保护 (SIP) 锁定，无法直接移除",
                            "[System Protected] \(itemName) is protected by macOS System Integrity Protection (SIP).")
            } else {
                return l10n("【容器隔离/权限受阻】\(itemName) 移入废纸篓受阻 (Operation not permitted)。请检查“完全磁盘访问权限”或手动清除",
                            "[Container/TCC Blocked] Moving \(itemName) to Trash is not permitted by macOS security (TCC).")
            }
        }

        // 5. General Permission / TCC
        if desc.contains("permission") || desc.contains("denied") || desc.contains("eacces") {
            return l10n("【权限受限】\(itemName) 受到 macOS 权限保护，需在“系统设置”中授予对应访问权限",
                        "[Restricted] \(itemName) is protected. Please check System Settings for required permissions.")
        }

        return l10n("【处理中断】\(itemName) 操作未成功: \(error.localizedDescription)",
                    "[Failed] Failed on \(itemName): \(error.localizedDescription)")
    }
}

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
        var privilegeQueue: [CleanItem] = []

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
                let errStr = l10n("【隐私保护拦截】\(item.name) 正处于隐私保险箱保护中，已拒绝清理", "[Privacy Locked] \(item.name) is currently protected in Privacy Vault.")
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

            if item.path.hasSuffix("com.apple.TimeMachine.Snapshots") || item.path == "/private/var/db/TimeMachineSnapshots" {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
                proc.arguments = ["thinlocalsnapshots", "/", "10000000000", "4"]
                try? proc.run()
                proc.waitUntilExit()
                successCount += 1
                reclaimedBytes += item.sizeBytes
                actuallyCleanedPaths.append(item.path)
                onProgress?(item, true, nil)
                continue
            }

            do {
                if useTrash {
                    try await FileUtils.moveToTrash(path: item.path)
                } else {
                    try await FileUtils.removePermanently(path: item.path)
                }
                successCount += 1
                reclaimedBytes += item.sizeBytes
                actuallyCleanedPaths.append(item.path)
                onProgress?(item, true, nil)
            } catch {
                // Fallback: If deleting the entire cache folder failed (e.g. running browser holding an open socket/lock),
                // attempt to clean unheld internal cache items so space is still reclaimed!
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

                // 自动无痕提权兜底 (Auto-escalation for Traceless Clean)
                let errDesc = error.localizedDescription.lowercased()
                if errDesc.contains("permission") || errDesc.contains("not permitted") || errDesc.contains("denied") || (error as? CocoaError)?.code == .fileWriteNoPermission || (error as? CocoaError)?.code == .fileReadNoPermission {
                    
                    // UX Interaction Fix: Never prompt for Root Password if we mathematically know TCC will block it anyway.
                    // ~/Library/Containers strictly requires Full Disk Access. Root (sudo rm) cannot bypass TCC.
                    let hasFDA = FileManager.default.isReadableFile(atPath: NSHomeDirectory() + "/Library/Safari/Bookmarks.plist")
                    if item.path.contains("Library/Containers") && !hasFDA {
                        failCount += 1
                        let userFriendlyReason = l10n("【缺失 FDA 权限】\(item.name) 是沙盒容器。macOS TCC 保护机制禁止在未开启“完全磁盘访问权限”时清理，即使输入密码也无效。请前往“系统设置 > 隐私与安全性”授权。", 
                        "[FDA Missing] \(item.name) is a sandbox container. macOS TCC blocks deletion without Full Disk Access. Root password cannot bypass this. Grant FDA in System Settings.")
                        errors.append(userFriendlyReason)
                        onProgress?(item, false, userFriendlyReason)
                        continue
                    }
                    
                    privilegeQueue.append(item)
                    continue
                }

                failCount += 1
                let userFriendlyReason = CleanerEngine.localizedErrorMessage(for: error, itemName: item.name, path: item.path)
                errors.append(userFriendlyReason)
                onProgress?(item, false, userFriendlyReason)
            }
        }

        // --- 集中式批量提权清除 (Batch Root Escalation, based on PureMac standard) ---
        if !privilegeQueue.isEmpty && !dryRun {
            // Write paths NUL-separated to a temp file, then use xargs -0 rm -rf
            let paths = privilegeQueue.map { $0.path }
            let payload = paths.joined(separator: "\u{0}")
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("macaegis_root_clean_\(UUID().uuidString).txt")
            
            if let data = payload.data(using: .utf8) {
                try? data.write(to: tempURL, options: .atomic)
                let safeTempPath = tempURL.path.replacingOccurrences(of: "'", with: "'\\''")
                // using xargs -0 to handle all spaces, quotes, and newlines safely, exactly like PureMac.
                let appleScript = "do shell script \"/usr/bin/xargs -0 /bin/rm -rf -- < '\(safeTempPath)'\" with administrator privileges"
                
                var errorInfo: NSDictionary?
                if let script = NSAppleScript(source: appleScript) {
                    _ = script.executeAndReturnError(&errorInfo)
                    try? FileManager.default.removeItem(at: tempURL)
                    
                    for pItem in privilegeQueue {
                        if !FileManager.default.fileExists(atPath: pItem.path) {
                            successCount += 1
                            reclaimedBytes += pItem.sizeBytes
                            actuallyCleanedPaths.append(pItem.path)
                            onProgress?(pItem, true, nil)
                        } else {
                            failCount += 1
                            let errDesc = (errorInfo?[NSAppleScript.errorMessage] as? String) ?? ""
                            let userFriendlyReason: String
                            
                            if errDesc.contains("Operation not permitted") {
                                userFriendlyReason = l10n("【需完全磁盘访问权限】macOS 底层沙盒 (TCC) 拦截了删除请求。即使输入密码提权，也必须在“系统设置 > 隐私与安全性 > 完全磁盘访问权限”中勾选 MacAegis 才能清理此容器。", 
                                "[FDA Required] macOS TCC blocked deletion. Even with root password, you must grant Full Disk Access in System Settings to clean this container.")
                            } else if errDesc.contains("User canceled") || errDesc.contains("canceled") {
                                userFriendlyReason = l10n("【已取消】您取消了密码授权，跳过提权清理。", "[Cancelled] You cancelled the password prompt.")
                            } else {
                                userFriendlyReason = l10n("【系统级锁定】\(pItem.name) 提权失败，受 macOS SIP 严格保护。\(errDesc)", "[SIP/Root Failed] \(pItem.name) could not be removed. \(errDesc)")
                            }
                            errors.append(userFriendlyReason)
                            onProgress?(pItem, false, userFriendlyReason)
                        }
                    }
                }
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

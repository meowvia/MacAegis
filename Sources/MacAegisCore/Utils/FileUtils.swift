import Foundation
import AppKit

public struct FileUtils: Sendable {
    /// Expand tilde in path (e.g. ~/Library -> /Users/xxx/Library)
    public static func expandPath(_ path: String) -> String {
        return (path as NSString).expandingTildeInPath
    }

    /// Check if path exists
    public static func fileExists(atPath path: String) -> Bool {
        let expanded = expandPath(path)
        return FileManager.default.fileExists(atPath: expanded)
    }

    /// Fast and accurate directory/file allocated size calculation
    public static func calculateSize(atPath path: String) -> Int64 {
        let expanded = expandPath(path)
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: expanded, isDirectory: &isDir) else {
            return 0
        }

        let url = URL(fileURLWithPath: expanded)

        if !isDir.boolValue {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                return Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
            } catch {
                return 0
            }
        }

        // Directory traversal with autoreleasepool
        var totalSize: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey]

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            autoreleasepool {
                do {
                    let values = try fileURL.resourceValues(forKeys: resourceKeys)
                    if values.isRegularFile == true {
                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        totalSize += Int64(size)
                    }
                } catch {}
            }
        }

        return totalSize
    }

    /// Robust multi-tiered move to Trash (supports root-owned and App Store /Applications bundles via privileged escalation)
    @MainActor
    public static func moveToTrash(path: String) async throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        let url = URL(fileURLWithPath: expanded)

        // Use FileManager for silent background trash operation. 
        // This PREVENTS UI deadlocks from NSWorkspace native prompts on background threads.
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            // If it's a critical error (permission denied for root caches), we simply throw it.
            // We NO LONGER fallback to AppleScript Finder prompts automatically because doing so
            // in a loop for 50 cache files will cause a massive UI freeze/spam.
            throw error
        }
    }

    /// Privileged move to ~/.Trash using macOS administrator authorization
    public static func privilegedMoveToTrash(path: String) throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }

        let trashDir = expandPath("~/.Trash")
        let fileName = (expanded as NSString).lastPathComponent
        var targetTrashPath = (trashDir as NSString).appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: targetTrashPath) {
            let baseName = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            let timestamp = Int(Date().timeIntervalSince1970)
            let newName = ext.isEmpty ? "\(baseName)_\(timestamp)" : "\(baseName)_\(timestamp).\(ext)"
            targetTrashPath = (trashDir as NSString).appendingPathComponent(newName)
        }

        let uid = getuid()
        let gid = getgid()

        let safeSource = expanded.replacingOccurrences(of: "'", with: "'\\''")
        let safeDest = targetTrashPath.replacingOccurrences(of: "'", with: "'\\''")

        let command = "/bin/mv -f '\(safeSource)' '\(safeDest)' && /usr/sbin/chown -R \(uid):\(gid) '\(safeDest)'"
        let safeCommand = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")

        let appleScriptSource = "do shell script \"\(safeCommand)\" with administrator privileges"

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: appleScriptSource) else {
            throw NSError(domain: "MacAegisError", code: 513, userInfo: [NSLocalizedDescriptionKey: "无法初始化系统授权脚本"])
        }

        _ = script.executeAndReturnError(&errorInfo)

        if let err = errorInfo {
            let errNumber = err[NSAppleScript.errorNumber] as? Int ?? 0
            if errNumber == -128 {
                throw NSError(domain: "MacAegisError", code: -128, userInfo: [
                    NSLocalizedDescriptionKey: l10n("用户取消了管理员身份授权，卸载未能完成", "Administrator authorization was cancelled by user")
                ])
            }
            let errMsg = err[NSAppleScript.errorMessage] as? String ?? "未知授权执行错误"
            throw NSError(domain: "MacAegisError", code: errNumber, userInfo: [
                NSLocalizedDescriptionKey: l10n("管理员授权执行失败: \(errMsg)", "Privileged execution failed: \(errMsg)")
            ])
        }

        if FileManager.default.fileExists(atPath: expanded) {
            throw NSError(domain: "MacAegisError", code: 513, userInfo: [
                NSLocalizedDescriptionKey: l10n("管理员权限执行后文件仍未被移除", "File remains unremoved after privileged execution")
            ])
        }
    }

    /// Permanently remove item with privileged fallback
    @MainActor
    public static func removePermanently(path: String) async throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        let url = URL(fileURLWithPath: expanded)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // If direct removal fails, fallback to recycle (which handles native auth prompts)
            try await moveToTrash(path: path)
        }
    }

    /// Privileged permanent removal using macOS administrator authorization
    public static func privilegedRemovePermanently(path: String) throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }

        let safeSource = expanded.replacingOccurrences(of: "'", with: "'\\''")
        let command = "/bin/rm -rf '\(safeSource)'"
        let safeCommand = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")

        let appleScriptSource = "do shell script \"\(safeCommand)\" with administrator privileges"

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: appleScriptSource) else {
            throw NSError(domain: "MacAegisError", code: 513, userInfo: [NSLocalizedDescriptionKey: "无法初始化系统授权脚本"])
        }

        _ = script.executeAndReturnError(&errorInfo)

        if let err = errorInfo {
            let errNumber = err[NSAppleScript.errorNumber] as? Int ?? 0
            if errNumber == -128 {
                throw NSError(domain: "MacAegisError", code: -128, userInfo: [
                    NSLocalizedDescriptionKey: l10n("用户取消了管理员身份授权，卸载未能完成", "Administrator authorization was cancelled by user")
                ])
            }
            let errMsg = err[NSAppleScript.errorMessage] as? String ?? "未知授权执行错误"
            throw NSError(domain: "MacAegisError", code: errNumber, userInfo: [
                NSLocalizedDescriptionKey: l10n("管理员授权执行失败: \(errMsg)", "Privileged execution failed: \(errMsg)")
            ])
        }

        if FileManager.default.fileExists(atPath: expanded) {
            throw NSError(domain: "MacAegisError", code: 513, userInfo: [
                NSLocalizedDescriptionKey: l10n("管理员权限执行后文件仍未被移除", "File remains unremoved after privileged execution")
            ])
        }
    }

    /// Recursively empty contents of a directory without removing the directory itself.
    /// Returns the approximate number of reclaimed bytes.
    public static func emptyDirectoryContents(atPath path: String) -> Int64 {
        let expanded = expandPath(path)
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: expanded) else { return 0 }
        var reclaimed: Int64 = 0
        for item in items {
            let itemPath = (expanded as NSString).appendingPathComponent(item)
            let itemSize = calculateSize(atPath: itemPath)
            do {
                try fm.removeItem(atPath: itemPath)
                reclaimed += itemSize
            } catch {
                // Ignore items currently held open by processes
            }
        }
        return reclaimed
    }
}

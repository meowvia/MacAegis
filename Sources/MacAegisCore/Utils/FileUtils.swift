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
            options: [.skipsHiddenFiles],
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

    /// Robust multi-tiered move to Trash (supports root-owned /Applications bundles via AppleScript/Finder)
    public static func moveToTrash(path: String) throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        let url = URL(fileURLWithPath: expanded)

        // Tier 1: Try standard FileManager.trashItem
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return
        } catch {
            // If Tier 1 failed (e.g. permission on /Applications/SomeApp.app), try Tier 2: AppleScript Finder trash
            let scriptSource = "tell application \"Finder\" to delete POSIX file \"\(expanded)\""
            var errorInfo: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                _ = script.executeAndReturnError(&errorInfo)
                if errorInfo == nil && !FileManager.default.fileExists(atPath: expanded) {
                    return
                }
            }

            // If still exists, rethrow original error
            throw error
        }
    }

    /// Permanently remove item
    public static func removePermanently(path: String) throws {
        let expanded = expandPath(path)
        let url = URL(fileURLWithPath: expanded)
        try FileManager.default.removeItem(at: url)
    }
}

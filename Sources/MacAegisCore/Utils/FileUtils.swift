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

    /// Checks if a file/folder can be moved to Trash without triggering macOS SecurityAgent Touch ID / Admin Password prompt.
    /// Apple's FileManager.trashItem prompts for credentials if moving root-owned or privileged files.
    public static func canTrashWithoutPrivilegeEscalation(path: String) -> Bool {
        let expanded = expandPath(path)
        let fm = FileManager.default
        guard fm.fileExists(atPath: expanded) else { return false }

        // 1. Sandbox and Group Containers trigger macOS SecurityAgent / Finder modals when trashItem is invoked.
        // Direct removeItem must be used instead to ensure 100% silent, prompt-free deletion.
        if expanded.contains("/Library/Containers") || expanded.contains("/Library/Group Containers") {
            return false
        }

        // 2. Root/System system directories require privileges and will trigger Touch ID/Password dialogs
        if expanded.hasPrefix("/System") || expanded.hasPrefix("/private/var") || expanded.hasPrefix("/Library") || expanded.hasPrefix("/usr") {
            return false
        }

        // 3. Any file not owned by the current running user
        var statBuf = stat()
        if lstat(expanded, &statBuf) == 0 {
            if statBuf.st_uid != getuid() {
                return false
            }
        }

        // 4. Never attempt trashing .Trashes root folders
        if expanded.hasSuffix("/.Trashes") || expanded == "/.Trashes" {
            return false
        }

        // 5. Parent folder must be writable by current user
        let parent = (expanded as NSString).deletingLastPathComponent
        guard fm.isWritableFile(atPath: parent) else { return false }

        return true
    }

    /// Safe move to Trash off the main thread.
    /// Strictly avoids calling trashItem on root-owned / system files to prevent endless Touch ID / password prompts.
    public static func moveToTrash(path: String) async throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }

        // Check if moving to Trash requires elevation
        if !canTrashWithoutPrivilegeEscalation(path: expanded) {
            // Instead of invoking coreservicesd/SecurityAgent prompt via trashItem,
            // attempt direct removeItem or throw permission error for graceful handling
            let url = URL(fileURLWithPath: expanded)
            try FileManager.default.removeItem(at: url)
            return
        }

        let url = URL(fileURLWithPath: expanded)
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    /// Permanently remove item off the main thread
    public static func removePermanently(path: String) async throws {
        let expanded = expandPath(path)
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        let url = URL(fileURLWithPath: expanded)
        try FileManager.default.removeItem(at: url)
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

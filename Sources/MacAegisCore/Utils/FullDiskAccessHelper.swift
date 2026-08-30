import Foundation
import AppKit

public final class FullDiskAccessHelper: Sendable {
    public static let shared = FullDiskAccessHelper()

    private init() {}

    /// Check whether MacAegis has been granted Full Disk Access (FDA)
    public func hasFullDiskAccess() -> Bool {
        // Method 1: Check access to TCC protected user directory
        let tccUserPath = FileUtils.expandPath("~/Library/Application Support/com.apple.TCC/TCC.db")
        if FileManager.default.isReadableFile(atPath: tccUserPath) {
            return true
        }

        // Method 2: Check access to Safari history/data
        let safariPath = FileUtils.expandPath("~/Library/Safari")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: safariPath), !contents.isEmpty {
            return true
        }

        // Method 3: Check system log directory readability
        let systemLogPath = "/private/var/log/DiagnosticMessages"
        if FileManager.default.isReadableFile(atPath: systemLogPath) {
            return true
        }

        return false
    }

    /// Open macOS System Settings directly to Full Disk Access panel
    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

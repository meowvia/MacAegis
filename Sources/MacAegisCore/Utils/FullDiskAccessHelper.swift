import Foundation
import AppKit

public final class FullDiskAccessHelper: Sendable {
    public static let shared = FullDiskAccessHelper()

    private init() {}

    /// Check whether MacAegis has been granted Full Disk Access (FDA)
    public func hasFullDiskAccess() -> Bool {
        // Method 1: Check System TCC Database (Often readable with FDA)
        let systemTCC = "/Library/Application Support/com.apple.TCC/TCC.db"
        if FileManager.default.isReadableFile(atPath: systemTCC) {
            return true
        }
        
        // Method 2: Check User TCC Database (Legacy macOS)
        let tccUserPath = FileUtils.expandPath("~/Library/Application Support/com.apple.TCC/TCC.db")
        if FileManager.default.isReadableFile(atPath: tccUserPath) {
            return true
        }

        // METHOD 3 (ACTIVE TRIGGER): Attempt to list contents of the strictly protected Messages directory.
        // This is CRITICAL: We must use `contentsOfDirectory` (which opens the directory) rather than
        // `isReadableFile` (which just stats it). Opening a protected directory is what forces macOS 
        // to automatically add MacAegis to the System Settings FDA list!
        let messagesDir = FileUtils.expandPath("~/Library/Messages")
        if let _ = try? FileManager.default.contentsOfDirectory(atPath: messagesDir) {
            return true
        }
        
        // METHOD 4 (ACTIVE TRIGGER): Fallback check on Safari's strictly protected sub-files.
        let safariBookmarks = FileUtils.expandPath("~/Library/Safari/Bookmarks.plist")
        if let _ = try? Data(contentsOf: URL(fileURLWithPath: safariBookmarks)) {
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

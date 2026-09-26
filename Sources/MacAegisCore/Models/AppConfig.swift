import Foundation

public struct AppConfig: Sendable {
    /// Global brand name - change here to globally rename the app across all UI and reports in 1 second!
    public static let appName = "MacAegis"
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }
    public static let defaultBundleIdentifier = "com.studio.macaegis"
    public static let configDirName = "macaegis"
}

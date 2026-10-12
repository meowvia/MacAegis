import Foundation
import AppKit

public struct RunningAppResource: Identifiable, Sendable {
    public let id: pid_t
    public let name: String
    public let bundleId: String?
    public let icon: String
    public let isTerminated: Bool

    public init(
        id: pid_t,
        name: String,
        bundleId: String?,
        icon: String = "📦",
        isTerminated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.icon = icon
        self.isTerminated = isTerminated
    }
}

public final class ProcessSentinel: Sendable {
    public static let shared = ProcessSentinel()

    public init() {}

    /// List active foreground and user background GUI applications
    public func fetchActiveUserApplications() -> [RunningAppResource] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        var results: [RunningAppResource] = []

        for app in runningApps {
            guard app.activationPolicy == .regular || app.activationPolicy == .accessory else {
                continue
            }

            let name = app.localizedName ?? "未知应用"
            let pid = app.processIdentifier
            let bundleId = app.bundleIdentifier

            results.append(RunningAppResource(
                id: pid,
                name: name,
                bundleId: bundleId,
                icon: app.activationPolicy == .regular ? "🖥" : "⚙️",
                isTerminated: app.isTerminated
            ))
        }

        return results
    }

    /// Check if a specific application is actively running
    public func isAppRunning(nameOrBundleId: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let target = nameOrBundleId.lowercased()
        return runningApps.contains { app in
            if let name = app.localizedName?.lowercased(), name.contains(target) { return true }
            if let bundleId = app.bundleIdentifier?.lowercased(), bundleId.contains(target) { return true }
            return false
        }
    }

    /// Safely request an application to terminate
    public func terminateApp(pid: pid_t, force: Bool = false) -> Bool {
        if let app = NSRunningApplication(processIdentifier: pid) {
            if force {
                return app.forceTerminate()
            } else {
                return app.terminate()
            }
        }
        return false
    }
}

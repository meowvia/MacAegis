import SwiftUI
import AppKit
@preconcurrency import UserNotifications
import MacAegisCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Enforce Single Instance
        if let bundleID = Bundle.main.bundleIdentifier {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if runningApps.count > 1 {
                for app in runningApps where app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                    app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }
                NSApp.terminate(nil)
                return
            }
        }

        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let isTrashWatcher = UserDefaults.standard.object(forKey: "trashWatcher") as? Bool ?? true
        if isTrashWatcher {
            TrashWatcherService.shared.startWatching()
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MacAegisAppMovedToTrash"),
            object: nil,
            queue: .main
        ) { notif in
            guard let appName = notif.userInfo?["appName"] as? String else { return }
            Task { @MainActor in
                Self.notifyAppMovedToTrash(appName: appName)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            if let window = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
                window.delegate = self
                window.isMovableByWindowBackground = true
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private static func notifyAppMovedToTrash(appName: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = l10n("检测到应用被移入废纸篓", "App Moved to Trash")
            content.body = l10n("「\(appName)」已移入废纸篓，点击清理关联的残留数据与缓存。", "'\(appName)' moved to Trash. Click to clean associated leftover data.")
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let keepInMemory = UserDefaults.standard.object(forKey: "keepInMemoryOnClose") as? Bool ?? true
        if !keepInMemory {
            NSApp.terminate(nil)
            return true
        }
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Self.showMainWindow()
        return true
    }

    public static func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.className.contains("Window") }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.isMovableByWindowBackground = true
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.isMovableByWindowBackground = true
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct MacAegisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("MacAegis", id: "main_window") {
            MainView()
                .frame(minWidth: 980, minHeight: 660)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    StatusBarController.shared.setup(dashboardVM: DashboardViewModel.shared)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1000, height: 680)
    }
}

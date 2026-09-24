import SwiftUI
import AppKit
import ObjectiveC
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
                    app.activate(options: [.activateAllWindows])
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
                self.configureWindow(window)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func configureWindow(_ window: NSWindow) {
        window.delegate = self
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        // Enable native window dragging across any non-interactive background space
        if let contentView = window.contentView {
            let hostingClass: AnyClass = type(of: contentView)
            let selector = #selector(getter: NSView.mouseDownCanMoveWindow)
            if let method = class_getInstanceMethod(hostingClass, selector) {
                let types = method_getTypeEncoding(method)
                let block: @convention(block) (AnyObject) -> Bool = { _ in true }
                let imp = imp_implementationWithBlock(block)
                class_replaceMethod(hostingClass, selector, imp, types)
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let keepInMemory = UserDefaults.standard.object(forKey: "keepInMemoryOnClose") as? Bool ?? true
        if keepInMemory {
            NSApp.setActivationPolicy(.accessory)
            return false
        }
        return true
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
        
        // Super aggressive unhide and activation
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        var foundWindow = false
        
        for window in NSApp.windows {
            if !window.className.contains("NSStatusBarWindow") && !window.className.contains("NSPopover") && !(window is NSPanel) {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                window.alphaValue = 1.0
                window.setIsVisible(true)
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true
                window.makeKeyAndOrderFront(nil)
                foundWindow = true
                break
            }
        }
        
        if !foundWindow {
            // If the window is truly lost, use NSWorkspace to re-launch the app bundle
            // This natively triggers SwiftUI to recreate the WindowGroup
            if let bundlePath = Bundle.main.bundlePath as String? {
                if let url = URL(string: "file://" + bundlePath) {
                    let config = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
                }
            }
        }
    }
}

@main
struct MacAegisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("MacAegis", id: "main_window") {
            MainView()
                .frame(minWidth: 860, minHeight: 560)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    StatusBarController.shared.setup(dashboardVM: DashboardViewModel.shared)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 880, height: 580)
    }
}

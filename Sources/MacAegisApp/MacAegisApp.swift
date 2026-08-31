import SwiftUI
import AppKit
import MacAegisCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            if let window = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
                window.delegate = self
                window.makeKeyAndOrderFront(nil)
            }
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
        if let window = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
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
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    StatusBarController.shared.setup(dashboardVM: DashboardViewModel.shared)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 960, height: 640)
    }
}

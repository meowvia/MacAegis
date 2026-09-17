import AppKit
import SwiftUI
import Combine
import MacAegisCore

@MainActor
public final class StatusBarController: NSObject {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private var dashboardVM: DashboardViewModel?
    private var isSetup = false

    private var lastClickTime: TimeInterval = 0
    private var pendingClickWorkItem: DispatchWorkItem?
    private var staticLogoImage: NSImage?

    public func setup(dashboardVM: DashboardViewModel) {
        guard !isSetup else { return }
        isSetup = true

        self.dashboardVM = dashboardVM
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Prepare the static template logo
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        if let sfSymbol = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            let size = NSSize(width: 18, height: 18)
            let image = NSImage(size: size, flipped: false) { rect in
                let destRect = NSRect(
                    x: (rect.width - sfSymbol.size.width) / 2,
                    y: (rect.height - sfSymbol.size.height) / 2,
                    width: sfSymbol.size.width,
                    height: sfSymbol.size.height
                )
                sfSymbol.draw(in: destRect)
                return true
            }
            image.isTemplate = true
            self.staticLogoImage = image
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarCardView(viewModel: dashboardVM) {
                self.hidePopover()
                AppDelegate.showMainWindow()
            }
        )
        self.popover = popover

        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(handleStatusBarClick(_:))
            button.sendAction(on: [.leftMouseUp])
            button.image = self.staticLogoImage
            button.imagePosition = .imageOnly
        }

        dashboardVM.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)

        updateStatusItemTitle()
    }

    @objc private func handleStatusBarClick(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        let now = Date().timeIntervalSince1970
        let timeDiff = now - lastClickTime
        lastClickTime = now
        
        let clickCount = NSApp.currentEvent?.clickCount ?? 1

        // Use custom time-based double click detection since NSStatusItem swallows click counts
        if clickCount >= 2 || timeDiff < 0.45 {
            pendingClickWorkItem?.cancel()
            pendingClickWorkItem = nil
            hidePopover()
            AppDelegate.showMainWindow()
            return
        }

        if popover.isShown {
            pendingClickWorkItem?.cancel()
            pendingClickWorkItem = nil
            popover.performClose(sender)
            return
        }

        pendingClickWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak button, weak popover] in
            guard let button = button, let popover = popover else { return }
            if !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
        self.pendingClickWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
    }

    public func hidePopover() {
        pendingClickWorkItem?.cancel()
        pendingClickWorkItem = nil
        popover?.performClose(nil)
    }

    public func updateVisibility(enabled: Bool) {
        statusItem?.isVisible = enabled
    }

    public func updateStatusItemTitle() {
        guard let button = statusItem?.button else { return }
        button.toolTip = AppConfig.appName
    }
}

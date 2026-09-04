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

    private var pendingClickWorkItem: DispatchWorkItem?

    public func setup(dashboardVM: DashboardViewModel) {
        guard !isSetup else { return }
        isSetup = true

        self.dashboardVM = dashboardVM
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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
        }

        // Listen to updates from DashboardViewModel
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
        let clickCount = NSApp.currentEvent?.clickCount ?? 1

        if clickCount >= 2 {
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

        // 150ms debounce for single-click to guarantee 0 flicker on double-clicks
        pendingClickWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak button, weak popover] in
            guard let button = button, let popover = popover else { return }
            if !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
        self.pendingClickWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    public func hidePopover() {
        pendingClickWorkItem?.cancel()
        pendingClickWorkItem = nil
        popover?.performClose(nil)
    }

    private var cachedLogoImages: [ProxyMode: NSImage] = [:]
    private var lastRenderedMode: ProxyMode?

    public func updateVisibility(enabled: Bool) {
        statusItem?.isVisible = enabled
    }

    public func updateStatusItemTitle() {
        guard let button = statusItem?.button, let vm = dashboardVM else { return }

        let mode = vm.networkSpeed.proxyMode
        if lastRenderedMode != mode {
            button.image = cachedLogo(for: mode)
            button.imagePosition = .imageOnly
            lastRenderedMode = mode
        }
        button.attributedTitle = NSAttributedString()
        button.title = ""
        button.toolTip = "\(AppConfig.appName) · \(mode.localizedTitle) (↓\(vm.networkSpeed.compactDownString) ↑\(vm.networkSpeed.compactUpString))"
    }

    private func cachedLogo(for mode: ProxyMode) -> NSImage {
        if let cached = cachedLogoImages[mode] {
            return cached
        }
        let img = createLogoImage(for: mode)
        cachedLogoImages[mode] = img
        return img
    }

    private func createLogoImage(for proxyMode: ProxyMode) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor
        switch proxyMode {
        case .global:
            color = NSColor(red: 239/255.0, green: 68/255.0, blue: 68/255.0, alpha: 1.0) // #EF4444 (Crimson)
        case .rule:
            color = NSColor(red: 16/255.0, green: 185/255.0, blue: 129/255.0, alpha: 1.0) // #10B981 (Emerald)
        case .direct:
            color = NSColor(red: 2/255.0, green: 132/255.0, blue: 199/255.0, alpha: 1.0) // #0284C7 (Ocean Blue)
        }

        let baseConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [color])
        let finalConfig = baseConfig.applying(colorConfig)

        let image = NSImage(size: size, flipped: false) { rect in
            if let sfSymbol = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil)?.withSymbolConfiguration(finalConfig) {
                let destRect = NSRect(
                    x: (rect.width - sfSymbol.size.width) / 2,
                    y: (rect.height - sfSymbol.size.height) / 2,
                    width: sfSymbol.size.width,
                    height: sfSymbol.size.height
                )
                sfSymbol.draw(in: destRect)
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}

// Extension to parse Hex into NSColor cleanly
extension NSColor {
    convenience init?(hexString: String) {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

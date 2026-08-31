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
            button.action = #selector(togglePopover(_:))
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

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    public func hidePopover() {
        popover?.performClose(nil)
    }

    public func updateVisibility(enabled: Bool) {
        statusItem?.isVisible = enabled
    }

    public func updateStatusItemTitle() {
        guard let button = statusItem?.button, let vm = dashboardVM else { return }

        let attributed = NSMutableAttributedString()

        // 1. Network Speed (Colorized based on Proxy Mode: Red for Global, Green for Rule, Neutral for Direct)
        let speedString = vm.networkSpeed.menuBarDisplayString
        let proxyHex = vm.networkSpeed.proxyMode.colorHex
        let speedColor = NSColor(hexString: proxyHex) ?? .labelColor

        let speedAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
            .foregroundColor: speedColor
        ]
        attributed.append(NSAttributedString(string: speedString, attributes: speedAttr))

        // 2. Divider / Space
        let spaceAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.headerTextColor
        ]
        attributed.append(NSAttributedString(string: "  ", attributes: spaceAttr))

        // 3. Temp (Default crisp 100% standard system menu bar color)
        let tempString = vm.thermalAndFan.formattedTemperature
        let neutralAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.headerTextColor
        ]
        attributed.append(NSAttributedString(string: tempString, attributes: neutralAttr))

        // 4. Space & CPU (Default crisp 100% standard system menu bar color)
        attributed.append(NSAttributedString(string: " ", attributes: spaceAttr))
        let cpuString = "\(String(format: "%.0f", vm.systemMetrics.cpuUsagePercent))%"
        attributed.append(NSAttributedString(string: cpuString, attributes: neutralAttr))

        button.attributedTitle = attributed
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

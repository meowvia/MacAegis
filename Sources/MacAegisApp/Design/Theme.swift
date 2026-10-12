import SwiftUI
import AppKit
import MacAegisCore

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return l10n("跟随系统", "System")
        case .light: return l10n("浅色", "Light")
        case .dark: return l10n("深色", "Dark")
        }
    }

    public var icon: String {
        switch self {
        case .system: return "gearshape"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public enum AppTheme: String, CaseIterable, Identifiable {
    case standard = "standard"
    case custom = "custom"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .standard: return l10n("原生流光", "Liquid Glass")
        case .custom: return l10n("自定义壁纸", "Custom Wallpaper")
        }
    }

    public var subtitle: String {
        switch self {
        case .standard: return l10n("原生极简 · 晶莹透澈 · 零内存负担", "Native minimalist glass · Zero memory footprint")
        case .custom: return l10n("本地壁纸 · 全屏无损等比 · 流光毛玻璃", "Lossless aspect ratio · Frosted glass blur")
        }
    }

    public var isCustom: Bool {
        return self == .custom
    }

    public var isAnimeTheme: Bool {
        return self == .custom
    }

    public var assetName: String? {
        switch self {
        case .standard: return nil
        case .custom: return "custom"
        }
    }
}

public final class ThemeAssetLoader: @unchecked Sendable {
    public static let shared = ThemeAssetLoader()
    private var cachedImages: [String: NSImage] = [:]
    private let lock = NSLock()

    public static let customThemeURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacAegis", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_theme.jpg")
    }()

    private init() {}

    public func hasCustomTheme() -> Bool {
        FileManager.default.fileExists(atPath: Self.customThemeURL.path)
    }

    public func removeCustomTheme() {
        lock.lock()
        defer { lock.unlock() }
        cachedImages.removeValue(forKey: "custom")
        cachedImages.removeValue(forKey: "custom_thumb")
        try? FileManager.default.removeItem(at: Self.customThemeURL)
    }

    public func importCustomTheme(from sourceURL: URL) -> Bool {
        guard let sourceImg = NSImage(contentsOf: sourceURL) else { return false }
        guard let tiffData = sourceImg.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.90]) else {
            return false
        }
        do {
            try jpegData.write(to: Self.customThemeURL)
            lock.lock()
            cachedImages["custom"] = sourceImg
            cachedImages.removeValue(forKey: "custom_thumb")
            lock.unlock()
            return true
        } catch {
            return false
        }
    }

    public func loadThemeBackground(named name: String) -> NSImage? {
        return loadThemeImage(named: name)
    }

    public func loadThemeCharacter(named name: String, isAction: Bool = false) -> NSImage? {
        return nil
    }

    public func loadThemeImage(named name: String, isAction: Bool = false, isThumbnail: Bool = false) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }

        let cacheKey = isThumbnail ? "\(name)_thumb" : name
        if let cached = cachedImages[cacheKey] {
            return cached
        }

        if name == "custom" {
            if let customImg = NSImage(contentsOf: Self.customThemeURL) {
                cachedImages[cacheKey] = customImg
                return customImg
            }
            return nil
        }

        return nil
    }
}

public struct MacAegisTheme {
    // Dynamic Semantic Backgrounds
    public static var canvasBackground: Color {
        Color.clear
    }

    public static var surfaceBase: Color {
        Color(NSColor.controlBackgroundColor)
    }

    public static var surfaceElevated: Color {
        Color(NSColor.underPageBackgroundColor)
    }

    // Accents
    public static let emerald = Color(hex: "10B981")
    public static let cyan = Color(hex: "06B6D4")
    public static let blue = Color(hex: "2563EB")
    public static let violet = Color(hex: "8B5CF6")
    public static let amber = Color(hex: "F59E0B")
    public static let rose = Color(hex: "F43F5E")
    public static let slate = Color(hex: "64748B")

    // High-contrast semantic text colors
    public static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color(hex: "0F172A")
    }

    public static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.70) : Color(hex: "475569")
    }

    public static func tertiaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.45) : Color(hex: "64748B")
    }

    // Gradients
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let emeraldGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cyanGradient = LinearGradient(
        colors: [Color(hex: "06B6D4"), Color(hex: "0284C7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let purpleGradient = LinearGradient(
        colors: [Color(hex: "A855F7"), Color(hex: "6366F1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let amberGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let roseGradient = LinearGradient(
        colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Native AppKit Window Configurator & Draggable Area & Visual Effect
public struct WindowConfigurator: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.styleMask.insert(.fullSizeContentView)
            window.contentAspectRatio = NSSize(width: 880, height: 580)
            window.minSize = NSSize(width: 880, height: 580)
        }
        return view
    }
    public func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        if window.isOpaque {
            window.isOpaque = false
        }
        if window.backgroundColor != .clear {
            window.backgroundColor = .clear
        }
        if window.contentAspectRatio != NSSize(width: 880, height: 580) {
            window.contentAspectRatio = NSSize(width: 880, height: 580)
        }
        if window.minSize != NSSize(width: 880, height: 580) {
            window.minSize = NSSize(width: 880, height: 580)
        }
    }
}

public struct WindowDragArea: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> WindowDraggableNSView {
        WindowDraggableNSView()
    }
    public func updateNSView(_ nsView: WindowDraggableNSView, context: Context) {}
}

public final class WindowDraggableNSView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }

    public override func mouseDown(with event: NSEvent) {
        if let window = self.window {
            window.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

public struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .fullScreenUI
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(
        material: NSVisualEffectView.Material = .fullScreenUI,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> DraggableVisualEffectView {
        let view = DraggableVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: DraggableVisualEffectView, context: Context) {
        if nsView.material != material {
            nsView.material = material
        }
        if nsView.blendingMode != blendingMode {
            nsView.blendingMode = blendingMode
        }
    }
}

public final class DraggableVisualEffectView: NSVisualEffectView {
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }

    public override func mouseDown(with event: NSEvent) {
        if let window = self.window {
            window.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

// MARK: - Refined Liquid Glass Studio Card
public struct StudioCardContainer<Content: View>: View {
    var cornerRadius: CGFloat
    var isSelected: Bool
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered: Bool = false

    public init(cornerRadius: CGFloat = 12, isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.isSelected = isSelected
        self.content = content()
    }

    private var cardFill: Color {
        if isSelected {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.16 : 0.12)
        }
        if colorScheme == .dark {
            return isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.045)
        } else {
            return isHovered ? Color.white.opacity(0.60) : Color.white.opacity(0.42)
        }
    }

    private var cardBorder: Color {
        if isSelected {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.60 : 0.50)
        }
        if colorScheme == .dark {
            return isHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.09)
        } else {
            return isHovered ? Color.white.opacity(0.85) : Color.white.opacity(0.50)
        }
    }

    private var cardShadowColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(isHovered ? 0.18 : 0.06)
        } else {
            return Color.black.opacity(isHovered ? 0.06 : 0.02)
        }
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(cardBorder, lineWidth: 0.5)
            )
            .shadow(
                color: cardShadowColor,
                radius: isHovered ? 6 : 3,
                x: 0,
                y: isHovered ? 2 : 1
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.14)) {
                    isHovered = hovering
                }
            }
    }
}

public struct StudioCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var isSelected: Bool = false

    public func body(content: Content) -> some View {
        StudioCardContainer(cornerRadius: cornerRadius, isSelected: isSelected) {
            content
        }
    }
}

public extension View {
    func studioCard(cornerRadius: CGFloat = 12, isSelected: Bool = false) -> some View {
        self.modifier(StudioCardModifier(cornerRadius: cornerRadius, isSelected: isSelected))
    }

    func bentoCard(cornerRadius: CGFloat = 12, highlightColor: Color = Color.blue) -> some View {
        self.studioCard(cornerRadius: cornerRadius, isSelected: false)
    }
}

// MARK: - Pure Button Style (Eliminates Blue Focus Rings and Platform Artifacts)
public struct PureButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .contentShape(Rectangle())
            .focusable(false)
            .focusEffectDisabled()
    }
}

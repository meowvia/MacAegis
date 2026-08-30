import SwiftUI
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

public struct MacAegisTheme {
    // Dynamic Semantic Backgrounds
    public static var canvasBackground: Color {
        Color(NSColor.windowBackgroundColor)
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

public struct StudioCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var isSelected: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        colorScheme == .dark
                            ? (isSelected ? Color(hex: "1E2433") : (isHovered ? Color(hex: "181C26") : Color(hex: "12151E")))
                            : (isSelected ? Color.blue.opacity(0.08) : (isHovered ? Color.white : Color(hex: "FFFFFF")))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected
                            ? Color.blue.opacity(0.5)
                            : (colorScheme == .dark ? Color.white.opacity(isHovered ? 0.12 : 0.06) : Color.black.opacity(isHovered ? 0.08 : 0.04)),
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(isHovered ? 0.06 : 0.03),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.14)) {
                    isHovered = hovering
                }
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
    }
}

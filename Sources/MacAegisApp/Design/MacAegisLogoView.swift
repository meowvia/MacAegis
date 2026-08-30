import SwiftUI

public struct MacAegisLogoView: View {
    var size: CGFloat = 32
    var isGlowing: Bool = false

    public init(size: CGFloat = 32, isGlowing: Bool = false) {
        self.size = size
        self.isGlowing = isGlowing
    }

    public var body: some View {
        ZStack {
            if isGlowing {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(Color(hex: "10B981").opacity(0.40))
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: size * 0.3)
            }

            // Apple Squircle Base with Obsidian Gradient
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "182620"),
                            Color(hex: "0D1512"),
                            Color(hex: "080C0A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "34D399").opacity(0.8),
                                    Color(hex: "10B981").opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.0, size * 0.045)
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)

            // Inner Emblem: Emerald Aegis Shield
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "6EE7B7"),
                            Color(hex: "10B981"),
                            Color(hex: "059669")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "10B981").opacity(0.6), radius: size * 0.12, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
}

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
                    .fill(Color(hex: "38BDF8").opacity(0.45))
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: size * 0.3)
            }

            // Apple Squircle Base with Ocean Obsidian Gradient
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "0C1A2E"),
                            Color(hex: "08101E"),
                            Color(hex: "040810")
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
                                    Color(hex: "38BDF8").opacity(0.9),
                                    Color(hex: "0284C7").opacity(0.6),
                                    Color(hex: "818CF8").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.0, size * 0.045)
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)

            // Inner Emblem: Ocean Blue Liquid Aegis Shield
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "38BDF8"),
                            Color(hex: "0284C7"),
                            Color(hex: "2563EB")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "0284C7").opacity(0.7), radius: size * 0.12, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
}

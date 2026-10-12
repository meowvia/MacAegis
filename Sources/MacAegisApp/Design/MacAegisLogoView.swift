import SwiftUI
import AppKit

public struct MacAegisLogoView: View {
    var size: CGFloat = 32
    var isGlowing: Bool = false

    public init(size: CGFloat = 32, isGlowing: Bool = false) {
        self.size = size
        self.isGlowing = isGlowing
    }

    private var appIcon: NSImage? {
        if let img = NSImage(named: "AppIcon"), img.isValid {
            return img
        }
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let img = NSImage(contentsOfFile: path), img.isValid {
            return img
        }
        if let path = Bundle.main.path(forResource: "logo", ofType: "png"),
           let img = NSImage(contentsOfFile: path), img.isValid {
            return img
        }
        return nil
    }

    public var body: some View {
        ZStack {
            if isGlowing {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(Color(hex: "0284C7").opacity(0.45))
                    .frame(width: size * 1.25, height: size * 1.25)
                    .blur(radius: size * 0.25)
            }

            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                vectorLiquidGlassFallback
            }
        }
        .frame(width: size, height: size)
    }

    private var vectorLiquidGlassFallback: some View {
        ZStack {
            // Apple Squircle Base with Royal Blue Liquid Glass Refractive Gradient
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1E40AF"),
                            Color(hex: "1D4ED8"),
                            Color(hex: "0F172A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.65),
                                    Color(hex: "38BDF8").opacity(0.75),
                                    Color(hex: "1E3A8A").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.0, size * 0.05)
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)

            // Inner Emblem: Dark Metallic Shield + Luminous Frosted Cyan Padlock
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "0F172A"),
                            Color(hex: "1E293B")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "38BDF8").opacity(0.5), radius: size * 0.1, x: 0, y: 1)

            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.26, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "E0F2FE"),
                            Color(hex: "38BDF8")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "38BDF8"), radius: size * 0.15)
        }
    }
}


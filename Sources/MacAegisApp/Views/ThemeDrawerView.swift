import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MacAegisCore

public struct ThemeDrawerView: View {
    @Binding var selectedTheme: AppTheme
    var onClose: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var hasCustomTheme: Bool = ThemeAssetLoader.shared.hasCustomTheme()
    @State private var customThumbnail: NSImage? = ThemeAssetLoader.shared.loadThemeImage(named: "custom", isThumbnail: true)

    public init(selectedTheme: Binding<AppTheme>, onClose: @escaping () -> Void) {
        self._selectedTheme = selectedTheme
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "38BDF8"), Color(hex: "818CF8")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(l10n("个性化与外观", "Personalization"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Text(l10n("原生流光 · 自定义壁纸 · 无损等比自适应", "Liquid glass · Custom wallpaper · Lossless fit"))
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().opacity(0.2)

            // Scrollable Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // Option 1: 原生流光 (Standard Liquid Glass)
                    standardGlassCard

                    // Option 2: 本地自定义壁纸 (Custom Wallpaper)
                    customWallpaperSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 330)
        .background(
            ZStack {
                VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                Color(hex: "090D16").opacity(colorScheme == .dark ? 0.35 : 0.08)
            }
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25))
                .frame(width: 0.8),
            alignment: .leading
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.20), radius: 18, x: -6, y: 0)
        .onAppear {
            refreshCustomState()
        }
    }

    // MARK: - Option 1: 原生流光卡片
    private var standardGlassCard: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTheme = .standard
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    // Glass Refraction Icon Box
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "090D16").opacity(colorScheme == .dark ? 0.85 : 0.20),
                                    Color(hex: "1E293B").opacity(colorScheme == .dark ? 0.95 : 0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "38BDF8").opacity(0.7), lineWidth: 1.2)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "macwindow")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "38BDF8"))
                            }
                        )
                        .frame(width: 54, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(l10n("原生流光", "Liquid Glass"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)

                            Text(l10n("默认推荐", "Default"))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "10B981"))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(Color(hex: "10B981").opacity(0.14)))
                        }

                        Text(l10n("极简毛玻璃 · 零内存占用", "Minimalist glass · Zero memory"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if selectedTheme == .standard {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "38BDF8"))
                            .font(.system(size: 17, weight: .bold))
                    }
                }

                Text(l10n("macOS 原生半透明材质与壁纸折射，跟随浅色/深色模式动态调节，纯净轻量。", "macOS native translucent glass with dynamic desktop refraction. Pure and lightweight."))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTheme == .standard ? Color(hex: "38BDF8").opacity(0.10) : Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTheme == .standard ? Color(hex: "38BDF8").opacity(0.65) : Color.white.opacity(0.08), lineWidth: selectedTheme == .standard ? 1.5 : 0.8)
                    )
            )
        }
        .buttonStyle(PureButtonStyle())
        .focusable(false)
        .focusEffectDisabled()
    }

    // MARK: - Option 2: 本地自定义壁纸
    private var customWallpaperSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(l10n("自定义壁纸", "Custom Wallpaper"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text(l10n("1:1 等比自适应", "Lossless Fit"))
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(Color(hex: "38BDF8"))
            }

            if hasCustomTheme {
                // 已有自定义壁纸卡片
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTheme = .custom
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            if let img = customThumbnail ?? ThemeAssetLoader.shared.loadThemeImage(named: "custom", isThumbnail: true) {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 124)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 124)
                            }

                            if selectedTheme == .custom {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "38BDF8"))
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                                    .font(.system(size: 18, weight: .bold))
                                    .padding(8)
                            }
                        }
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedTheme == .custom ? Color(hex: "38BDF8") : Color.white.opacity(0.15), lineWidth: selectedTheme == .custom ? 2 : 0.8)
                        )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()

                    HStack(spacing: 8) {
                        Button(action: selectAndImportCustomImage) {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.badge.arrow.forward")
                                    .font(.system(size: 11))
                                Text(l10n("更换壁纸", "Change Wallpaper"))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5.5)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                        .focusEffectDisabled()

                        Spacer()

                        Button(action: removeCustomImage) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9.5))
                                Text(l10n("恢复默认", "Reset"))
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5.5)
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                        .focusEffectDisabled()
                    }

                    // Adaptation description tag
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "10B981"))
                            .frame(width: 5, height: 5)
                        Text(l10n("任意视窗尺寸无损填充 · 次级页面 46px 深度毛玻璃", "Lossless fill across all ratios · 46px blur on sub-pages"))
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedTheme == .custom ? Color(hex: "38BDF8").opacity(0.08) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTheme == .custom ? Color(hex: "38BDF8").opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            } else {
                // 未导入时的引导导入卡片
                Button(action: selectAndImportCustomImage) {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: "38BDF8"))

                        VStack(spacing: 3) {
                            Text(l10n("导入本地壁纸", "Import Local Wallpaper"))
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(.primary)

                            Text(l10n("支持 JPG / PNG / WebP / HEIC\n硬件加速无损等比缩放与次级页面高斯模糊", "Supports JPG/PNG/WebP/HEIC with lossless aspect ratio & sub-page blur"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                                    )
                                    .foregroundColor(Color.secondary.opacity(0.35))
                            )
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
        }
    }

    // MARK: - Actions
    private func selectAndImportCustomImage() {
        let panel = NSOpenPanel()
        panel.title = l10n("选择自定义主题壁纸图片", "Select Custom Theme Wallpaper")
        panel.allowedContentTypes = [
            UTType.jpeg,
            UTType.png,
            UTType(filenameExtension: "webp") ?? .image,
            UTType.heic
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            if ThemeAssetLoader.shared.importCustomTheme(from: url) {
                refreshCustomState()
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTheme = .custom
                }
            }
        }
    }

    private func removeCustomImage() {
        ThemeAssetLoader.shared.removeCustomTheme()
        refreshCustomState()
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTheme = .standard
        }
    }

    private func refreshCustomState() {
        hasCustomTheme = ThemeAssetLoader.shared.hasCustomTheme()
        customThumbnail = ThemeAssetLoader.shared.loadThemeImage(named: "custom", isThumbnail: true)
    }
}

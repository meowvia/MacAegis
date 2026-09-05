
import SwiftUI
import MacAegisCore

public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case uninstaller = "uninstaller"
    case privacyVault = "privacy_vault"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return l10n("智能清理", "Smart Clean")
        case .uninstaller: return l10n("应用卸载", "Uninstaller")
        case .privacyVault: return l10n("隐私隐匿", "Privacy Conceal")
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return "bolt.shield.fill"
        case .uninstaller: return "trash"
        case .privacyVault: return "lock.shield"
        }
    }
}

public struct MainView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hasShownLanguageHint_v1") private var hasShownLanguageHint: Bool = false
    @ObservedObject private var dashboardVM = DashboardViewModel.shared
    @StateObject private var uninstallerVM = UninstallerViewModel()
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var showingSettingsModal: Bool = false
    @State private var showLanguageBubble: Bool = false
    @State private var isBreathingGlow: Bool = false
    @State private var showOnboarding: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // macOS 26 Ethereal Liquid Glass Cosmic Canvas (Window-wide)
            cosmicLiquidGlassBackdrop

            VStack(spacing: 0) {
                // Top Studio Header Bar (macOS 26 Seamless Ambient Melt)
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    .background(
                        TitleBarBackgroundView()
                            .onTapGesture(count: 2) {
                                MainView.toggleWindowZoom()
                            }
                            .ignoresSafeArea(.all, edges: .top)
                    )

                // Main Stage (Zero-latency instant rendering, zero offscreen alpha compositing)
                Group {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(
                            viewModel: dashboardVM,
                            onNavigateToUninstaller: { selectedTab = .uninstaller },
                            onNavigateToPrivacyVault: { selectedTab = .privacyVault }
                        )
                    case .uninstaller:
                        UninstallerDropView(
                            viewModel: uninstallerVM,
                            onBack: { selectedTab = .dashboard }
                        )
                    case .privacyVault:
                        PrivacyVaultView(
                            onBack: { selectedTab = .dashboard }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // First-Launch Ethereal Language Switcher Floating Bubble (顺滑精致提示)
            if showLanguageBubble {
                languageHintTooltipBubble
                    .padding(.top, 46)
                    .padding(.trailing, 18)
                    .zIndex(999)
            }

            // Settings Inline Overlay Drawer (Zero AppKit Sheet Deadlocks, 100% Smooth)
            // 首次启动前置权限引导 (Onboarding)
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .zIndex(1001)
            }

            if showingSettingsModal {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingSettingsModal = false
                            }
                        }

                    SettingsView(onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingSettingsModal = false
                        }
                    })
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1000)
            }
        }
        .frame(minWidth: 980, minHeight: 660)
        
        .background(MacAegisTheme.canvasBackground)
        .preferredColorScheme(appearanceMode.colorScheme)
        .id("main_view_\(loc.appLanguage.rawValue)")
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                isBreathingGlow = true
            }
            
            // Onboarding FDA Check
            let tccPath = NSHomeDirectory() + "/Library/Application Support/com.apple.TCC"
            let hasFDA = (try? FileManager.default.contentsOfDirectory(atPath: tccPath)) != nil
            if !hasFDA {
                showOnboarding = true
            }
            if !hasShownLanguageHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        showLanguageBubble = true
                    }
                }
            }
        }
    }

    // MARK: - First-Launch Floating Tooltip Bubble
    private var languageHintTooltipBubble: some View {
        Button(action: {
            hasShownLanguageHint = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showLanguageBubble = false
                showingSettingsModal = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8"), Color(hex: "818CF8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n("支持中英文双语切换", "Switch to Chinese / English"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Text(l10n("点击设置齿轮可切换语言", "Click Settings to change language"))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer(minLength: 4)

                Button(action: {
                    hasShownLanguageHint = true
                    withAnimation(.easeOut(duration: 0.25)) {
                        showLanguageBubble = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(4)
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0F172A").opacity(0.95), Color(hex: "1E293B").opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "38BDF8").opacity(0.8), Color(hex: "C084FC").opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color(hex: "38BDF8").opacity(0.4), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(PureButtonStyle())
        .focusable(false)
        .focusEffectDisabled()
        .frame(width: 220)
        .transition(.scale(scale: 0.85, anchor: .topTrailing).combined(with: .opacity))
    }

    // MARK: - Top Studio Header Bar
    private var headerBar: some View {
        ZStack {
            // Mode Switcher centered absolutely in the window (immune to right stats jitter)
            HStack(spacing: 8) {
                ForEach(NavigationTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .bold))
                            Text(tab.title)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8.5)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.18),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.35),
                                                            Color.white.opacity(0.08)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: Color(hex: "38BDF8").opacity(0.25), radius: 8, x: 0, y: 3)
                                }
                            }
                        )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                }
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selectedTab)
            .padding(4)

            // Outer Left Brand and Right Controls
            HStack(spacing: 20) {
                // App Brand (Seamless implicit click to GitHub)
                HStack(spacing: 9) {
                    MacAegisLogoView(size: 28, isGlowing: true)
                    Text(AppConfig.appName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: "https://github.com/meowvia/MacAegis") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .help(l10n("点击访问 MacAegis 官方 GitHub 仓库", "Click to visit MacAegis on GitHub"))

                Spacer()

                // Right Quick Controls (Network Speed + Settings)
                HStack(spacing: 10) {
                    // Network Speed & Proxy Mode Indicator (monospaced + minWidth to prevent jitter)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: dashboardVM.networkSpeed.proxyMode.colorHex))
                            .frame(width: 6, height: 6)
                        Text(dashboardVM.networkSpeed.menuBarDisplayString)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(Color(hex: dashboardVM.networkSpeed.proxyMode.colorHex))
                    }
                    .frame(minWidth: 105, alignment: .center)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.08))
                    )

                    // Settings Button
                    Button(action: {
                        hasShownLanguageHint = true
                        withAnimation { showLanguageBubble = false }
                        showingSettingsModal = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                    .help(l10n("打开偏好设置", "Open Settings"))
                }
                .padding(.trailing, 2)
            }
        }
    }

    public static func toggleWindowZoom() {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) else { return }
        let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") ?? "Maximize"
        if action == "Minimize" {
            window.miniaturize(nil)
            return
        } else if action == "None" {
            return
        }
        window.zoom(nil)
    }

    // MARK: - Ethereal Cosmic Liquid Glass Backdrop
    @Environment(\.colorScheme) private var envColorScheme

    private var cosmicLiquidGlassBackdrop: some View {
        ZStack {
            if envColorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(hex: "17192B"),
                        Color(hex: "101221"),
                        Color(hex: "090A12")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient Stardust Micro-particles with Enhanced Dynamic Breathing
                stardustCanvas
                    .opacity(isBreathingGlow ? 0.95 : 0.35)

                // Iridescent Magenta / Violet Glow (Upper Left)
                RadialGradient(
                    colors: [Color(hex: "C084FC").opacity(isBreathingGlow ? 0.22 : 0.14), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 580
                )
                .ignoresSafeArea()

                // Electric Cyan Caustics Bloom (Center Right)
                RadialGradient(
                    colors: [Color(hex: "38BDF8").opacity(isBreathingGlow ? 0.20 : 0.11), Color.clear],
                    center: .center,
                    startRadius: 80,
                    endRadius: 520
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "F8FAFC"),
                        Color(hex: "EDF2F7"),
                        Color(hex: "E2E8F0")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color(hex: "38BDF8").opacity(0.22), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
        }
    }

    // Ambient Stardust Micro-particles Canvas (32 Celestial Breathing Points)
    private var stardustCanvas: some View {
        Canvas { context, size in
            let particles: [(x: CGFloat, y: CGFloat, r: CGFloat, alpha: Double)] = [
                // Top area
                (0.08, 0.08, 1.6, 0.55),
                (0.18, 0.12, 2.2, 0.65),
                (0.32, 0.06, 1.4, 0.40),
                (0.48, 0.14, 2.0, 0.60),
                (0.68, 0.09, 1.5, 0.45),
                (0.82, 0.15, 2.4, 0.70),
                (0.94, 0.07, 1.3, 0.50),

                // Upper-mid area
                (0.05, 0.28, 1.8, 0.50),
                (0.22, 0.26, 1.2, 0.35),
                (0.78, 0.25, 1.9, 0.55),
                (0.92, 0.32, 2.3, 0.65),

                // Mid area
                (0.07, 0.48, 2.0, 0.60),
                (0.15, 0.55, 1.3, 0.40),
                (0.86, 0.46, 1.4, 0.45),
                (0.95, 0.52, 2.1, 0.65),

                // Center subtle accents
                (0.28, 0.42, 1.2, 0.30),
                (0.72, 0.38, 1.5, 0.40),
                (0.35, 0.62, 1.1, 0.25),
                (0.65, 0.66, 1.3, 0.35),

                // Lower-mid area
                (0.06, 0.70, 2.4, 0.65),
                (0.19, 0.76, 1.6, 0.45),
                (0.83, 0.68, 2.2, 0.60),
                (0.93, 0.74, 1.5, 0.50),

                // Bottom area
                (0.10, 0.88, 1.7, 0.55),
                (0.25, 0.92, 2.5, 0.70),
                (0.40, 0.86, 1.4, 0.40),
                (0.55, 0.94, 2.0, 0.60),
                (0.70, 0.89, 1.3, 0.45),
                (0.85, 0.93, 2.2, 0.65),
                (0.96, 0.88, 1.6, 0.50),

                // Edge accents
                (0.02, 0.40, 1.5, 0.45),
                (0.98, 0.42, 1.8, 0.55)
            ]
            for p in particles {
                if p.r >= 2.0 {
                    let halo = CGRect(
                        x: size.width * p.x - p.r * 2.2,
                        y: size.height * p.y - p.r * 2.2,
                        width: p.r * 4.4,
                        height: p.r * 4.4
                    )
                    context.fill(Path(ellipseIn: halo), with: .color(Color(hex: "38BDF8").opacity(p.alpha * 0.25)))
                }

                let rect = CGRect(
                    x: size.width * p.x - p.r,
                    y: size.height * p.y - p.r,
                    width: p.r * 2,
                    height: p.r * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(p.alpha)))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - AppKit TitleBar Background Representable
struct TitleBarBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> TitleBarNSView {
        return TitleBarNSView()
    }
    func updateNSView(_ nsView: TitleBarNSView, context: Context) {}
}

final class TitleBarNSView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}




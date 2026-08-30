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
        case .privacyVault: return l10n("隐私保险箱", "Privacy Vault")
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return "sparkles"
        case .uninstaller: return "trash"
        case .privacyVault: return "lock.shield"
        }
    }
}

public struct MainView: View {
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.zh.rawValue
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hasShownLanguageHint_v1") private var hasShownLanguageHint: Bool = false
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var uninstallerVM = UninstallerViewModel()
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var showingSettingsModal: Bool = false
    @State private var showLanguageBubble: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Top Studio Header Bar (macOS 26 Liquid Glass Translucency)
                headerBar
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)

                Divider().opacity(0.2)

                // Main Stage
                ZStack {
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
        }
        .frame(minWidth: 960, minHeight: 640)
        .background(MacAegisTheme.canvasBackground)
        .preferredColorScheme(appearanceMode.colorScheme)
        .id("main_view_\(appLanguage)")
        .sheet(isPresented: $showingSettingsModal) {
            SettingsView()
        }
        .onAppear {
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

            // Floating Segmented Mode Switcher (4 Focused Pillars)
            HStack(spacing: 4) {
                ForEach(NavigationTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.secondary.opacity(0.15) : Color.clear)
                        )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 0.8)
                    )
            )

            Spacer()

            // Right Quick Controls (Appearance + Network Speed + Settings)
            HStack(spacing: 8) {
                // Appearance Quick Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        switch appearanceMode {
                        case .system: appearanceMode = .light
                        case .light: appearanceMode = .dark
                        case .dark: appearanceMode = .system
                        }
                    }
                }) {
                    Image(systemName: appearanceMode.icon)
                        .font(.system(size: 11))
                        .foregroundColor(Color.blue)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.08)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()

                Divider().frame(height: 12).opacity(0.4)

                // Network Speed & Proxy Mode (杀手功能)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: dashboardVM.networkSpeed.proxyMode.colorHex))
                        .frame(width: 5, height: 5)
                    Text(dashboardVM.networkSpeed.menuBarDisplayString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: dashboardVM.networkSpeed.proxyMode.colorHex))
                }

                Divider().frame(height: 12).opacity(0.4)

                // Settings Button
                Button(action: {
                    hasShownLanguageHint = true
                    withAnimation { showLanguageBubble = false }
                    showingSettingsModal = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.08)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 4)
        }
    }
}

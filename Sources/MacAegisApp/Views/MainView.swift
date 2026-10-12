
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
        case .privacyVault: return l10n("独立空间", "Private Space")
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
    @AppStorage("selectedAppTheme") private var selectedTheme: AppTheme = .standard
    @AppStorage("hasShownLanguageHint_v1") private var hasShownLanguageHint: Bool = false
    @ObservedObject private var dashboardVM = DashboardViewModel.shared
    @StateObject private var uninstallerVM = UninstallerViewModel()
    @StateObject private var privacyVaultVM = PrivacyVaultViewModel()
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var showingSettingsModal: Bool = false
    @State private var showingThemeDrawer: Bool = false
    @State private var hasNewVersion: Bool = false
    @AppStorage("autoCheckUpdate") private var autoCheckUpdate: Bool = true
    @State private var showLanguageBubble: Bool = false
    @AppStorage("hasCompletedOnboarding_v1") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // macOS Ethereal Liquid Glass Cosmic Canvas (Window-wide Edge-to-Edge)
            cosmicLiquidGlassBackdrop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Studio Header Bar (seamlessly integrated into single Liquid Glass canvas)
                headerBar
                    .padding(.leading, 78)
                    .padding(.trailing, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    .background(WindowDragArea()) // Native draggable top bar with hardware performDrag

                // Main Stage
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
                            viewModel: privacyVaultVM,
                            onBack: { selectedTab = .dashboard }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // First-Launch Ethereal Language Switcher Floating Bubble
            if showLanguageBubble {
                languageHintTooltipBubble
                    .padding(.top, 46)
                    .padding(.trailing, 18)
                    .zIndex(999)
            }

            // Theme Gallery Drawer (Right side slide-out drawer)
            if showingThemeDrawer {
                ZStack(alignment: .trailing) {
                    Color.black.opacity(0.40)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                showingThemeDrawer = false
                            }
                        }

                    ThemeDrawerView(selectedTheme: $selectedTheme, onClose: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            showingThemeDrawer = false
                        }
                    })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1000)
            }

            // Settings Inline Overlay Drawer
            // 首次启动前置权限引导 (Onboarding)
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .zIndex(1002)
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
        .frame(minWidth: 860, minHeight: 560)
        .background(Color.clear)
        .preferredColorScheme(appearanceMode.colorScheme)
        .id("main_view_\(loc.appLanguage.rawValue)")
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notif in
            if let window = notif.object as? NSWindow, window.className.contains("Window"), !(window is NSPanel) {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isMovableByWindowBackground = true
                window.styleMask.insert(.fullSizeContentView)
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    if window.delegate !== appDelegate {
                        window.delegate = appDelegate
                    }
                }
            }
        }
        .onAppear {
            // Onboarding FDA Check (Only if not previously dismissed or granted)
            if !FullDiskAccessHelper.shared.hasFullDiskAccess() && !hasCompletedOnboarding {
                showOnboarding = true
            }
            if !hasShownLanguageHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        showLanguageBubble = true
                    }
                }
            }
            
            // 3-Day Silent Auto Update Check
            if autoCheckUpdate {
                Task {
                    let lastCheck = UserDefaults.standard.double(forKey: "lastUpdateCheckTime")
                    let now = Date().timeIntervalSince1970
                    if now - lastCheck > 259200 {
                        if let update = await UpdateChecker.shared.checkForUpdates(), update.hasUpdate {
                            DispatchQueue.main.async {
                                hasNewVersion = true
                                UserDefaults.standard.set(now, forKey: "lastUpdateCheckTime")
                            }
                        } else {
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(now, forKey: "lastUpdateCheckTime")
                            }
                        }
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8"), Color(hex: "818CF8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.isEnglish ? "切换至简体中文" : "Switch to English")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(MacAegisTheme.primaryText(for: envColorScheme))
                    Text(loc.isEnglish ? "点击设置可更改界面语言" : "Click Settings to change language")
                        .font(.system(size: 9.5))
                        .foregroundColor(MacAegisTheme.secondaryText(for: envColorScheme))
                }

                Spacer(minLength: 4)

                Button(action: {
                    hasShownLanguageHint = true
                    withAnimation(.easeOut(duration: 0.2)) {
                        showLanguageBubble = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(MacAegisTheme.tertiaryText(for: envColorScheme))
                        .padding(4)
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(envColorScheme == .dark ? Color(hex: "131A29").opacity(0.85) : Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                envColorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.08),
                                lineWidth: 0.6
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(envColorScheme == .dark ? 0.25 : 0.06),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
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
            // Mode Switcher centered absolutely in the window
            HStack(spacing: 5) {
                ForEach(NavigationTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                            Text(tab.title)
                                .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                            if tab == .privacyVault {
                                Text("BETA")
                                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: "818CF8"))
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 1.5)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "818CF8").opacity(0.18))
                                            .overlay(Capsule().stroke(Color(hex: "818CF8").opacity(0.35), lineWidth: 0.5))
                                    )
                            }
                        }
                        .foregroundColor(
                            isSelected
                                ? (envColorScheme == .dark ? Color.white : Color(hex: "0F172A"))
                                : (envColorScheme == .dark ? Color.white.opacity(0.60) : Color(hex: "475569"))
                        )
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7.5)
                        .background(
                            Group {
                                if isSelected {
                                    Capsule()
                                        .fill(
                                            envColorScheme == .dark
                                                ? Color.white.opacity(0.15)
                                                : Color.white.opacity(0.75)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    envColorScheme == .dark
                                                        ? Color.white.opacity(0.25)
                                                        : Color.white,
                                                    lineWidth: 0.5
                                                )
                                        )
                                        .shadow(
                                            color: Color.black.opacity(envColorScheme == .dark ? 0.20 : 0.05),
                                            radius: 3,
                                            x: 0,
                                            y: 1
                                        )
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
            .padding(3.5)
            .background(
                Capsule()
                    .fill(envColorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(envColorScheme == .dark ? 0.12 : 0.35), lineWidth: 0.5)
                    )
            )

            // Outer Left Brand and Right Controls
            HStack(spacing: 20) {
                // App Brand (Seamless implicit click to GitHub)
                HStack(spacing: 10) {
                    MacAegisLogoView(size: 32, isGlowing: true)
                    Text(AppConfig.appName)
                        .font(.system(size: 17.5, weight: .bold, design: .rounded))
                        .foregroundColor(MacAegisTheme.primaryText(for: envColorScheme))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: "https://github.com/meowvia/MacAegis") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .help(l10n("点击访问 MacAegis 官方 GitHub 仓库", "Click to visit MacAegis on GitHub"))

                Spacer()

                // Right Quick Controls (Theme Quick Switcher & Settings)
                HStack(spacing: 8) {
                    // Theme Gallery Drawer Quick Button
                    Button(action: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showingThemeDrawer.toggle()
                        }
                    }) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(showingThemeDrawer ? Color(hex: "38BDF8") : MacAegisTheme.secondaryText(for: envColorScheme))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(showingThemeDrawer ? Color(hex: "38BDF8").opacity(0.18) : Color.primary.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(showingThemeDrawer ? Color(hex: "38BDF8").opacity(0.5) : Color.white.opacity(envColorScheme == .dark ? 0.12 : 0.35), lineWidth: 0.5)
                                    )
                            )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                    .help(l10n("打开主题画廊抽屉", "Open Theme Gallery"))

                    Button(action: {
                        hasShownLanguageHint = true
                        withAnimation { showLanguageBubble = false }
                        showingSettingsModal = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(MacAegisTheme.secondaryText(for: envColorScheme))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color.primary.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .stroke(Color.white.opacity(envColorScheme == .dark ? 0.12 : 0.35), lineWidth: 0.5)
                                        )
                                )
                            if hasNewVersion {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            }
                        }
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

    // MARK: - Native Unified Liquid Glass & Custom Wallpaper Backdrop (Full Window Draggable & Edge-to-Edge)
    @Environment(\.colorScheme) private var envColorScheme

    private var cosmicLiquidGlassBackdrop: some View {
        ZStack {
            // Native Window Configurator (enforcing isOpaque = false, backgroundColor = .clear, isMovableByWindowBackground = true)
            WindowConfigurator()
                .ignoresSafeArea()

            // True Liquid Glass Foundation with Wallpaper Refraction & Native Window Dragging
            VisualEffectBackground(material: .fullScreenUI, blendingMode: .behindWindow)
                .ignoresSafeArea()

            if selectedTheme == .custom,
               let customImg = ThemeAssetLoader.shared.loadThemeImage(named: "custom") {
                let isSubPage = (selectedTab == .uninstaller || selectedTab == .privacyVault)

                GeometryReader { geo in
                    ZStack {
                        // 1. Lossless 1:1 Aspect Ratio Full Screen Backdrop (Zero distortion, clipped)
                        Image(nsImage: customImg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .scaleEffect(isSubPage ? 1.06 : 1.0)
                            .blur(radius: isSubPage ? 46 : 0)
                            .animation(.easeInOut(duration: 0.30), value: isSubPage)
                            .allowsHitTesting(false)

                        if isSubPage {
                            // Sub-page pure frosted glass scrim: rich theme colors shine through with high contrast
                            Color.black.opacity(envColorScheme == .dark ? 0.38 : 0.16)
                                .transition(.opacity)
                                .allowsHitTesting(false)
                        } else {
                            // Top atmospheric gradient for window header contrast
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(envColorScheme == .dark ? 0.30 : 0.16),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .init(x: 0.5, y: 0.25)
                            )
                            .allowsHitTesting(false)
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            } else {
                // Native Standard Liquid Glass Ambient Shimmer
                Group {
                    if envColorScheme == .dark {
                        Color(hex: "090D16").opacity(0.20)
                            .ignoresSafeArea()

                        RadialGradient(
                            colors: [Color(hex: "38BDF8").opacity(0.08), Color.clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 520
                        )
                        .ignoresSafeArea()
                    } else {
                        Color.white.opacity(0.20)
                            .ignoresSafeArea()

                        RadialGradient(
                            colors: [Color(hex: "38BDF8").opacity(0.05), Color.clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 500
                        )
                        .ignoresSafeArea()
                    }
                }
                .allowsHitTesting(false)
            }

            // Window-wide hairline edge border for polished glass definition
            Rectangle()
                .strokeBorder(Color.white.opacity(envColorScheme == .dark ? 0.12 : 0.35), lineWidth: 0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}




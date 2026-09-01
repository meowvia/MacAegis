import SwiftUI
import AppKit
import MacAegisCore

public struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onNavigateToUninstaller: () -> Void
    var onNavigateToPrivacyVault: () -> Void

    @State private var showingScanDetail: Bool = false
    @State private var showingSettings: Bool = false
    @State private var activeCategoryFilter: [CleanCategory]? = nil
    @State private var activeDetailTitle: String = "全盘智能扫描明细"
    @State private var expandedCategories: Set<CleanCategory> = Set(CleanCategory.allCases)
    @State private var isOrbHovered: Bool = false
    @State private var isBreathingGlow: Bool = false

    public init(
        viewModel: DashboardViewModel,
        onNavigateToUninstaller: @escaping () -> Void,
        onNavigateToPrivacyVault: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToUninstaller = onNavigateToUninstaller
        self.onNavigateToPrivacyVault = onNavigateToPrivacyVault
    }

    public var body: some View {
        ZStack {
            // macOS 26 Ethereal Liquid Glass Cosmic Canvas
            cosmicLiquidGlassBackdrop

            if showingScanDetail {
                categoryDetailStreamView
            } else {
                masterReferenceCockpitView
            }

            // Floating Toast Notification
            if let toast = viewModel.actionToastMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .studioCard(cornerRadius: 12, isSelected: true)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
            }
        }
    }

    // MARK: - Ethereal Cosmic Liquid Glass Backdrop
    @Environment(\.colorScheme) var colorScheme

    private var cosmicLiquidGlassBackdrop: some View {
        ZStack {
            if colorScheme == .dark {
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

                // Iridescent Magenta / Violet Glow (Upper Left)
                RadialGradient(
                    colors: [Color(hex: "C084FC").opacity(0.18), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 550
                )
                .ignoresSafeArea()

                // Electric Cyan Caustics Bloom (Center Right)
                RadialGradient(
                    colors: [Color(hex: "38BDF8").opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 80,
                    endRadius: 500
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

    // MARK: - Master Reference UI Layout (Centered Grand Bubble + 4 Cleaning Dimension Pods)
    private var masterReferenceCockpitView: some View {
        VStack(spacing: 0) {
            // Top Greetings & Status Header (Centered)
            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    Text(l10n("你的 Mac 运行状态良好", "Your Mac is Running Smoothly"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "FBBF24"))
                        .font(.system(size: 16))
                }

                Text(l10n("纯原生轻量架构 · 深度安全清理 · 隐私隐匿守护", "Pure Native Architecture · Deep Safe Clean · Privacy Protection"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // Status Pill Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 6, height: 6)
                    Text(viewModel.isScanning ? l10n("正在极速深度扫描中...", "Scanning System...") : (viewModel.scanResult != nil ? l10n("全盘分析完成", "Analysis Complete") : l10n("极简原生 · 零常驻负担", "Pure Native · Zero Overhead")))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.08)))
                .padding(.top, 2)
            }
            .padding(.top, 14)

            Spacer(minLength: 8)

            // Main Stage: Left 2 Orbiting Bubbles + Center Grand Luminous Sphere + Right 2 Orbiting Bubbles
            HStack(alignment: .center, spacing: 36) {
                // Left Wing: 2 Floating Pods
                VStack(spacing: 36) {
                    // Pod 1: 系统缓存与日志 (Top-Left)
                    let systemSize = (viewModel.scanResult?.totalSize(for: .appCaches) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .systemCaches) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .systemLogs) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "shippingbox.fill",
                        iconBgGradient: [Color(hex: "94A3B8"), Color(hex: "64748B")],
                        title: l10n("系统缓存与日志", "System Caches & Logs"),
                        sizeString: ByteFormatter.format(systemSize),
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.appCaches, .systemCaches, .systemLogs]
                        activeDetailTitle = l10n("系统缓存与日志明细", "System Caches & Logs Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }

                    // Pod 2: 大文件与安装包 (Bottom-Left)
                    let downloadsSize = (viewModel.scanResult?.totalSize(for: .downloadsAndPackages) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .developerCaches) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "folder.fill",
                        iconBgGradient: [Color(hex: "A78BFA"), Color(hex: "7C3AED")],
                        title: l10n("大文件与安装包", "Large Files & Packages"),
                        sizeString: ByteFormatter.format(downloadsSize),
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.downloadsAndPackages, .developerCaches]
                        activeDetailTitle = l10n("大文件与安装包明细", "Large Files & Packages Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }
                }
                .frame(width: 210)

                // Center Stage: Grand 3D Luminous Aqua Glass Sphere Bubble (Enlarged & Centered)
                luminousAquaGlassSphereHero
                    .frame(width: 320)

                // Right Wing: 2 Floating Pods
                VStack(spacing: 36) {
                    // Pod 3: 隐私痕迹与通讯 (Top-Right)
                    let privacySize = (viewModel.scanResult?.totalSize(for: .messagingMedia) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .browserCaches) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "lock.shield.fill",
                        iconBgGradient: [Color(hex: "FBBF24"), Color(hex: "D97706")],
                        title: l10n("隐私痕迹与通讯", "Privacy & Messaging"),
                        sizeString: ByteFormatter.format(privacySize),
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.messagingMedia, .browserCaches]
                        activeDetailTitle = l10n("隐私痕迹与通讯数据明细", "Privacy & Messaging Traces Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }

                    // Pod 4: 废纸篓与残留 (Bottom-Right)
                    let leftoversSize = (viewModel.scanResult?.totalSize(for: .orphanLeftovers) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "trash.fill",
                        iconBgGradient: [Color(hex: "34D399"), Color(hex: "059669")],
                        title: l10n("已卸载残留文件", "Uninstalled App Leftovers"),
                        sizeString: ByteFormatter.format(leftoversSize),
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.orphanLeftovers]
                        activeDetailTitle = l10n("已卸载应用残留明细", "Uninstalled App Leftovers Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }
                }
                .frame(width: 210)
            }
            .frame(maxWidth: 860)
            .padding(.horizontal, 24)

            Spacer(minLength: 8)

            // Bottom Clickable Full Scan / List Entrance
            Button(action: {
                activeCategoryFilter = nil
                activeDetailTitle = l10n("全盘智能扫描明细", "All Scan Results")
                if viewModel.scanResult == nil && !viewModel.isScanning {
                    viewModel.startScan()
                }
                showingScanDetail = true
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "38BDF8"))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: "38BDF8"), radius: isBreathingGlow ? 6 : 1)
                        .scaleEffect(isBreathingGlow ? 1.25 : 0.85)

                    Text(l10n("查看全盘深度扫描列表 ↗", "View Full Disk Deep Scan List ↗"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "38BDF8").opacity(isBreathingGlow ? 0.85 : 0.35),
                                            Color(hex: "818CF8").opacity(isBreathingGlow ? 0.65 : 0.20)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: isBreathingGlow ? 1.4 : 0.8
                                )
                        )
                        .shadow(color: Color(hex: "38BDF8").opacity(isBreathingGlow ? 0.35 : 0.08), radius: isBreathingGlow ? 10 : 3, x: 0, y: 2)
                )
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .padding(.bottom, 16)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    isBreathingGlow = true
                }
            }
        }
    }

    // MARK: - Grand 3D Luminous Aqua Glass Sphere Bubble (可点击真·扫描按钮)
    private var luminousAquaGlassSphereHero: some View {
        VStack(spacing: 0) {
            Button(action: {
                viewModel.startScan()
            }) {
                ZStack {
                    // Layer 1: Ambient Multi-Spectral Outer Bloom (Outer Glow Aura)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "C084FC").opacity(isOrbHovered ? 0.55 : 0.40),
                                    Color(hex: "38BDF8").opacity(isOrbHovered ? 0.38 : 0.25),
                                    Color(hex: "6366F1").opacity(0.15),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 40,
                                endRadius: 150
                            )
                        )
                        .frame(width: 270, height: 270)
                        .blur(radius: isOrbHovered ? 24 : 20)

                    // Layer 2: Ambient Glowing Sparkle Accents
                    ForEach(0..<8) { i in
                        let angle = Double(i) * (Double.pi * 2 / 8)
                        let radius: CGFloat = 135
                        Circle()
                            .fill(i % 2 == 0 ? Color.white.opacity(0.8) : Color(hex: "38BDF8").opacity(0.7))
                            .frame(width: i % 3 == 0 ? 3.5 : 2.5, height: i % 3 == 0 ? 3.5 : 2.5)
                            .position(
                                x: 135 + radius * CGFloat(cos(angle)),
                                y: 135 + radius * CGFloat(sin(angle))
                            )
                            .blur(radius: 0.3)
                    }
                    .frame(width: 270, height: 270)

                    // Layer 3: Glass Sphere Core Body with Liquid Wave
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 230, height: 230)

                        // Inner Radial Specular Caustics
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.20),
                                        Color(hex: "38BDF8").opacity(0.08),
                                        Color(hex: "818CF8").opacity(0.15),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 230, height: 230)

                        // Internal Liquid Wave Membrane
                        liquidWaveMembrane
                            .frame(width: 210, height: 80)
                            .offset(y: 55)
                            .clipShape(Circle().size(width: 230, height: 230).offset(x: -10, y: -95))
                    }

                    // Layer 4: 3D Iridescent Optical Glass Rim Border
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(hex: "F472B6"),
                                    Color(hex: "C084FC"),
                                    Color(hex: "818CF8"),
                                    Color(hex: "38BDF8"),
                                    Color.white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isOrbHovered ? 3.0 : 2.4
                        )
                        .frame(width: 230, height: 230)
                        .shadow(color: Color(hex: "38BDF8").opacity(isOrbHovered ? 0.85 : 0.60), radius: isOrbHovered ? 16 : 12, x: 0, y: 0)

                    // Layer 5: Top-Left Crescent Specular Shine (光斑高光)
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 28)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -60, y: -60)

                    // Layer 6: Center Big Numbers & Typography Inside the Sphere
                    VStack(spacing: 3) {
                        if viewModel.isScanning {
                            ProgressView()
                                .scaleEffect(1.1)
                                .padding(.bottom, 4)

                            Text(l10n("正在极速全盘分析...", "Scanning Full Disk..."))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "38BDF8"))
                        } else {
                            Text(viewModel.selectedFormattedSize)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)

                            Text(l10n("可释放空间", "Space Reclaimable"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            if isOrbHovered {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text(l10n("点击再次扫描", "Click to Rescan"))
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "38BDF8"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: "38BDF8").opacity(0.18)))
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                    }
                }
                .frame(width: 270, height: 270)
                .scaleEffect(isOrbHovered ? 1.025 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOrbHovered)
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .onHover { isOrbHovered = $0 }

            // Primary Liquid Glass Pill Action Button (专职一键清理)
            Button(action: {
                viewModel.executeClean()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text(l10n("一键极速清理 (\(viewModel.selectedFormattedSize))", "Clean Now (\(viewModel.selectedFormattedSize))"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 230, height: 42)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "3B82F6"), Color(hex: "0284C7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.45), lineWidth: 1.2)
                        )
                        .shadow(color: Color(hex: "6366F1").opacity(0.50), radius: 12, x: 0, y: 5)
                )
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .disabled(viewModel.isScanning || viewModel.selectedItemIds.isEmpty)
            .opacity(viewModel.isScanning || viewModel.selectedItemIds.isEmpty ? 0.5 : 1.0)
            .offset(y: -14)
        }
    }

    // Liquid Wave Membrane Inside the Bubble
    private var liquidWaveMembrane: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                path.move(to: CGPoint(x: 0, y: height * 0.4))
                path.addCurve(
                    to: CGPoint(x: width, y: height * 0.4),
                    control1: CGPoint(x: width * 0.35, y: height * 0.25),
                    control2: CGPoint(x: width * 0.65, y: height * 0.55)
                )
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "818CF8").opacity(0.35),
                        Color(hex: "38BDF8").opacity(0.20),
                        Color(hex: "C084FC").opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    // MARK: - Orbiting Glass Bubble Pod (围绕大气泡的轻盈小气泡卡片)
    private func orbitingGlassBubblePod(
        icon: String,
        iconBgGradient: [Color],
        title: String,
        sizeString: String,
        yOffset: CGFloat,
        onAction: @escaping () -> Void
    ) -> some View {
        Button(action: onAction) {
            HStack(spacing: 12) {
                // Frosted Orb Icon Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconBgGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: iconBgGradient.first?.opacity(0.35) ?? Color.clear, radius: 5, x: 0, y: 2)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    Text(sizeString)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.50),
                                        Color(hex: "38BDF8").opacity(0.20),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
            )
            .offset(y: yOffset)
        }
        .buttonStyle(PureButtonStyle())
        .focusable(false)
        .focusEffectDisabled()
    }

    // MARK: - Computed Properties for Drill-Down Filtering
    private var displayedCategories: [CleanCategory] {
        if let filter = activeCategoryFilter {
            return CleanCategory.allCases.filter { filter.contains($0) }
        }
        return CleanCategory.allCases
    }

    private var displayedItems: [CleanItem] {
        guard let result = viewModel.scanResult else { return [] }
        return displayedCategories.flatMap { result.items(for: $0) }
    }

    private var displayedSelectedSizeString: String {
        let size = displayedItems
            .filter { viewModel.selectedItemIds.contains($0.id) }
            .reduce(0) { $0 + $1.sizeBytes }
        return ByteFormatter.format(size)
    }

    private var displayedSelectedCount: Int {
        return displayedItems.filter { viewModel.selectedItemIds.contains($0.id) }.count
    }

    // MARK: - Sub-Page: Category Detail Stream View (精准细分下钻)
    private var categoryDetailStreamView: some View {
        VStack(spacing: 0) {
            // Header Bar with Back Button
            HStack(spacing: 12) {
                Button(action: { showingScanDetail = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text(l10n("返回首页", "Back to Home"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.1)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()

                VStack(alignment: .leading, spacing: 1) {
                    Text(activeDetailTitle)
                        .font(.system(size: 15, weight: .bold))
                    Text(l10n("已选 \(displayedSelectedSizeString) (\(displayedSelectedCount) 项)", "Selected \(displayedSelectedSizeString) (\(displayedSelectedCount) items)"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Actions
                Button(l10n("全选", "Select All")) {
                    for item in displayedItems {
                        viewModel.selectedItemIds.insert(item.id)
                    }
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.blue)

                Text("•").foregroundColor(.secondary).font(.caption2)

                Button(l10n("取消全选", "Deselect All")) {
                    for item in displayedItems {
                        viewModel.selectedItemIds.remove(item.id)
                    }
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                Button(action: {
                    viewModel.executeClean()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text(l10n("清理已选 (\(displayedSelectedSizeString))", "Clean Selected (\(displayedSelectedSizeString))"))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "3B82F6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
                .disabled(displayedSelectedCount == 0 || viewModel.isCleaning)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.3)

            // Category Cards List
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.isScanning {
                        VStack(spacing: 14) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.top, 40)
                            Text(l10n("正在快速深度扫描分类数据...", "Scanning Category Data..."))
                                .font(.system(size: 14, weight: .bold))
                            Text(viewModel.scanProgressText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 360)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let result = viewModel.scanResult {
                        if displayedItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: "10B981"))
                                    .padding(.top, 40)
                                Text(l10n("当前分类无垃圾残留", "No Junk Files Found"))
                                    .font(.system(size: 14, weight: .bold))
                                Text(l10n("保持得非常干净，无需额外清理！✨", "Clean & optimal! No action required. ✨"))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(displayedCategories, id: \.rawValue) { category in
                                let items = result.items(for: category)
                                if !items.isEmpty {
                                    categoryDetailCard(category: category, items: items)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text(l10n("正在准备扫描...", "Preparing to scan..."))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            if viewModel.scanResult == nil && !viewModel.isScanning {
                viewModel.startScan()
            }
        }
    }

    private func categoryDetailCard(category: CleanCategory, items: [CleanItem]) -> some View {
        let isExpanded = expandedCategories.contains(category)
        let totalSize = items.reduce(0) { $0 + $1.sizeBytes }
        let selectedCount = items.filter { viewModel.selectedItemIds.contains($0.id) }.count

        return VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        if expandedCategories.contains(category) {
                            expandedCategories.remove(category)
                        } else {
                            expandedCategories.insert(category)
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))

                        Text(category.icon)
                            .font(.system(size: 13))

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text(category.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("(\(items.count) 项 · 已选 \(selectedCount) 项)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text(ByteFormatter.format(totalSize))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(totalSize > 0 ? .primary : .secondary)

                Toggle(isOn: Binding(
                    get: { selectedCount == items.count && !items.isEmpty },
                    set: { isChecked in
                        for item in items {
                            if isChecked { viewModel.selectedItemIds.insert(item.id) }
                            else { viewModel.selectedItemIds.remove(item.id) }
                        }
                    }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .disabled(items.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.06))

            if isExpanded && !items.isEmpty {
                Divider().opacity(0.2)
                VStack(spacing: 2) {
                    ForEach(items) { item in
                        itemDetailRow(item)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .studioCard(cornerRadius: 10)
    }

    private func itemDetailRow(_ item: CleanItem) -> some View {
        let isAppRunning = item.associatedAppName.map { ProcessSentinel.shared.isAppRunning(nameOrBundleId: $0) } ?? false
        let isChecked = viewModel.selectedItemIds.contains(item.id)

        return HStack(spacing: 10) {
            Toggle(isOn: Binding(
                get: { isChecked },
                set: { _ in viewModel.toggleItemSelection(id: item.id) }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    Text(item.safetyLevel.badge)
                        .font(.system(size: 8))
                    if isAppRunning {
                        Text("运行中")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color(hex: "F59E0B").opacity(0.12)))
                    }
                    if item.path.hasPrefix("/Volumes/") && !item.path.hasPrefix("/Volumes/Macintosh HD") {
                        Text("外置存储")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: "38BDF8"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color(hex: "38BDF8").opacity(0.12)))
                    }
                }
                Text(item.path)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if item.itemDescription.contains("⚠️") {
                    Text(item.itemDescription)
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: { viewModel.revealInFinder(path: item.path) }) {
                HStack(spacing: 3) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text("在访达中显示")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.08)))
            }
            .buttonStyle(.plain)

            Text(item.formattedSize)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(isChecked ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }
}


import SwiftUI
import AppKit
import MacAegisCore

// MARK: - Isolated High-Performance Cosmic Starfield
struct CosmicStarfieldBackdrop: View {
    private static let starCoordinates: [(x: CGFloat, y: CGFloat, size: CGFloat, baseAlpha: Double)] = [
        (0.06, 0.12, 2.2, 0.40),
        (0.16, 0.18, 1.6, 0.30),
        (0.26, 0.10, 2.6, 0.45),
        (0.86, 0.14, 2.0, 0.40),
        (0.93, 0.22, 1.8, 0.32),
        (0.74, 0.10, 2.4, 0.45),
        (0.05, 0.48, 2.0, 0.35),
        (0.10, 0.76, 2.6, 0.48),
        (0.04, 0.88, 1.8, 0.35),
        (0.20, 0.94, 2.2, 0.40),
        (0.95, 0.52, 2.2, 0.40),
        (0.89, 0.76, 2.8, 0.50),
        (0.96, 0.88, 1.6, 0.32),
        (0.78, 0.92, 2.4, 0.42),
        (0.36, 0.06, 1.8, 0.32),
        (0.64, 0.06, 2.2, 0.40),
        (0.40, 0.95, 1.6, 0.30),
        (0.60, 0.95, 2.0, 0.38)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                ForEach(0..<Self.starCoordinates.count, id: \.self) { idx in
                    let star = Self.starCoordinates[idx]
                    Circle()
                        .fill(idx % 3 == 0 ? Color(hex: "38BDF8") : Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: geo.size.width * star.x, y: geo.size.height * star.y)
                        .opacity(star.baseAlpha)
                }
            }
        }
        .allowsHitTesting(false)
        .drawingGroup() // Offload directly to Metal, 0 CPU overhead!
    }
}

public struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onNavigateToUninstaller: () -> Void
    var onNavigateToPrivacyVault: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var showingScanDetail: Bool = false
    @State private var showingSettings: Bool = false
    @State private var activeCategoryFilter: [CleanCategory]? = nil
    @State private var activeDetailTitle: String = "扫描详情"
    @State private var expandedCategories: Set<CleanCategory> = Set(CleanCategory.allCases)
    @State private var isOrbHovered: Bool = false

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
            // High-performance static ethereal starfield (0% CPU/GPU overhead)
            CosmicStarfieldBackdrop()

            if showingScanDetail {
                categoryDetailStreamView
            } else {
                masterReferenceCockpitView
            }
        }
        .overlay(
            Group {
                if viewModel.showingCleanErrorsSheet, let report = viewModel.lastCleanReport {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                            .onTapGesture { viewModel.showingCleanErrorsSheet = false }
                        
                        CleanErrorsSheetView(report: report) {
                            viewModel.showingCleanErrorsSheet = false
                        }
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 20)
                        .padding(40)
                    }
                }
            }
        )
    }

    private var dynamicSystemHealth: (title: String, icon: String, iconColor: Color, pillText: String, pillColor: Color) {
        if viewModel.isScanning || viewModel.isCleaning {
            return (
                title: l10n("正在全盘智能扫描...", "Scanning Full Disk..."),
                icon: "waveform.path.ecg",
                iconColor: Color(hex: "38BDF8"),
                pillText: l10n("正在排查系统垃圾、大文件与残留...", "Analyzing junk, large files & leftovers..."),
                pillColor: Color(hex: "06B6D4")
            )
        } else if let result = viewModel.scanResult {
            let safeReclaimable = result.safeSizeBytes

            if safeReclaimable >= 5 * 1024 * 1024 * 1024 {
                // 5GB 及以上：严重冗余
                return (
                    title: l10n("你的 Mac 发现较多系统垃圾，建议清理", "Your Mac Has Heavy Clutter, Clean Advised"),
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color(hex: "F59E0B"),
                    pillText: l10n("已发现 \(ByteFormatter.format(safeReclaimable)) 建议清理空间", "\(ByteFormatter.format(safeReclaimable)) Clutter Detected"),
                    pillColor: Color(hex: "F59E0B")
                )
            } else if safeReclaimable >= 500 * 1024 * 1024 {
                // 500MB ~ 5GB：适度优化
                return (
                    title: l10n("你的 Mac 发现可清理空间，建议优化", "Reclaimable Space Found, Optimization Suggested"),
                    icon: "shield.lefthalf.filled",
                    iconColor: Color(hex: "38BDF8"),
                    pillText: l10n("已发现 \(ByteFormatter.format(safeReclaimable)) 可优化空间", "\(ByteFormatter.format(safeReclaimable)) Reclaimable Found"),
                    pillColor: Color(hex: "38BDF8")
                )
            } else if safeReclaimable > 0 {
                // > 0MB 但 < 500MB：存在少量缓存，诚实提示
                return (
                    title: l10n("你的 Mac 发现少量临时缓存", "Minor Reclaimable Cache Found"),
                    icon: "shield.lefthalf.filled",
                    iconColor: Color(hex: "38BDF8"),
                    pillText: l10n("已发现 \(ByteFormatter.format(safeReclaimable)) 临时缓存", "\(ByteFormatter.format(safeReclaimable)) Cache Found"),
                    pillColor: Color(hex: "38BDF8")
                )
            } else {
                // 真正为 0：全盘纯净
                return (
                    title: l10n("你的 Mac 运行状态良好", "Your Mac is Optimal"),
                    icon: "checkmark.shield.fill",
                    iconColor: Color(hex: "10B981"),
                    pillText: l10n("扫描完成 · 状态良好", "Scan Complete · System Optimal"),
                    pillColor: Color(hex: "10B981")
                )
            }
        } else {
            // 未扫描待机态
            return (
                title: l10n("全盘智能扫描，释放存储空间", "Scan Your Mac to Reclaim Space"),
                icon: "magnifyingglass",
                iconColor: Color(hex: "38BDF8"),
                pillText: l10n("就绪待扫描 · 本地安全守护", "Ready to Scan · Local & Secure"),
                pillColor: Color(hex: "38BDF8")
            )
        }
    }

    private func cardSizeString(for size: Int64) -> String {
        if viewModel.isScanning || viewModel.isCleaning {
            return l10n("分析中...", "Analyzing...")
        }
        if viewModel.scanResult == nil {
            return l10n("待扫描", "Ready")
        }
        if size > 0 {
            return ByteFormatter.format(size)
        }
        return l10n("无冗余", "Clean")
    }

    // MARK: - Master Reference UI Layout (Centered Grand Bubble + 4 Cleaning Dimension Pods)
    private var masterReferenceCockpitView: some View {
        VStack(spacing: 0) {
            // Top Greetings & Status Header (Centered)
            VStack(spacing: 8) {
                let health = dynamicSystemHealth

                HStack(spacing: 8) {
                    Text(health.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Image(systemName: health.icon)
                        .foregroundColor(health.iconColor)
                        .font(.system(size: 20))
                }

                Text(l10n("原生轻量架构 · 智能深度清理 · 隐私安全守护", "Native Lightweight Architecture · Deep Smart Clean · Privacy Protection"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.85))
                    .padding(.top, 4)

                // Status / Result Card Presentation (Seamless In-Place Transition)
                if let report = viewModel.lastCleanReport {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                            .font(.system(size: 13, weight: .bold))

                        Text(l10n("已成功释放 \(report.formattedReclaimed) 空间 (\(report.successfulCount) 项)", "Reclaimed \(report.formattedReclaimed) (\(report.successfulCount) items)"))
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(.primary)

                        if report.failedCount > 0 {
                            Button(action: {
                                viewModel.showingCleanErrorsSheet = true
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text(l10n("\(report.failedCount) 项未清理 (查看)", "\(report.failedCount) skipped (View)"))
                                        .font(.system(size: 10.5, weight: .bold))
                                }
                                .foregroundColor(Color(hex: "F59E0B"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color(hex: "F59E0B").opacity(0.15)))
                            }
                            .buttonStyle(PureButtonStyle())
                            .focusable(false)
                            .focusEffectDisabled()
                        }

                        Button(action: {
                            viewModel.dismissCleanReport()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(4)
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                        .focusEffectDisabled()
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5.5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "10B981").opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "10B981").opacity(0.35), lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
                } else if let toast = viewModel.actionToastMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color(hex: "38BDF8"))
                            .font(.system(size: 12))
                        Text(toast)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.secondary.opacity(0.10)))
                    .padding(.top, 8)
                } else {
                    // Status Pill Badge (Centered with extra line spacing)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(health.pillColor)
                            .frame(width: 6, height: 6)
                        Text(health.pillText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.secondary.opacity(0.08)))
                    .padding(.top, 8)
                }
            }
            .padding(.top, 24)

            Spacer(minLength: 8)

            // Main Stage: Left 2 Orbiting Bubbles + Center Grand Luminous Sphere + Right 2 Orbiting Bubbles
            HStack(alignment: .center, spacing: 20) {
                // Left Wing: 2 Floating Pods (252pt)
                VStack(spacing: 22) {
                    // Pod 1: 系统垃圾与缓存 (Top-Left)
                    let systemSize = (viewModel.scanResult?.totalSize(for: .appCaches) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .systemCaches) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .systemLogs) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "shippingbox.fill",
                        iconBgGradient: [Color(hex: "94A3B8"), Color(hex: "64748B")],
                        title: l10n("系统垃圾与缓存", "System Junk & Caches"),
                        subtitle: l10n("系统日志 · 应用缓存 · 临时文件", "System Logs · App Caches · Temp Files"),
                        sizeString: cardSizeString(for: systemSize),
                        xOffset: 8,
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.appCaches, .systemCaches, .systemLogs]
                        activeDetailTitle = l10n("系统垃圾与缓存明细", "System Junk & Caches Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }

                    // Pod 2: 大型与陈旧文件 (Bottom-Left)
                    let downloadsSize = (viewModel.scanResult?.totalSize(for: .downloadsAndPackages) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .developerCaches) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .largeFiles) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "folder.fill",
                        iconBgGradient: [Color(hex: "A78BFA"), Color(hex: "7C3AED")],
                        title: l10n("大型与陈旧文件", "Large & Old Files"),
                        subtitle: l10n("安装映像 · 超大文件 · 开发者归档", "Disk Images · Large Files · Dev Caches"),
                        sizeString: cardSizeString(for: downloadsSize),
                        xOffset: 8,
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.downloadsAndPackages, .developerCaches, .largeFiles]
                        activeDetailTitle = l10n("大型与陈旧文件明细", "Large & Old Files Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }
                }
                .frame(width: 252)

                // Center Stage: Grand 3D Luminous Aqua Glass Sphere Bubble (Centered, No Deformation)
                luminousAquaGlassSphereHero
                    .frame(width: 280, height: 280)
                    .aspectRatio(1.0, contentMode: .fit)

                // Right Wing: 2 Floating Pods (252pt)
                VStack(spacing: 22) {
                    // Pod 3: 隐私与浏览痕迹 (Top-Right)
                    let privacySize = (viewModel.scanResult?.totalSize(for: .messagingMedia) ?? 0)
                        + (viewModel.scanResult?.totalSize(for: .browserCaches) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "lock.shield.fill",
                        iconBgGradient: [Color(hex: "FBBF24"), Color(hex: "D97706")],
                        title: l10n("隐私与浏览痕迹", "Privacy & Browsing Traces"),
                        subtitle: l10n("浏览器数据 · 通讯媒体 · 历史记录", "Browser Data · Chat Media · History"),
                        sizeString: cardSizeString(for: privacySize),
                        xOffset: -8,
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.messagingMedia, .browserCaches]
                        activeDetailTitle = l10n("隐私与浏览痕迹明细", "Privacy & Browsing Traces Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }

                    // Pod 4: 应用卸载残留 (Bottom-Right)
                    let leftoversSize = (viewModel.scanResult?.totalSize(for: .orphanLeftovers) ?? 0)
                    orbitingGlassBubblePod(
                        icon: "trash.fill",
                        iconBgGradient: [Color(hex: "34D399"), Color(hex: "059669")],
                        title: l10n("应用卸载残留", "Application Leftovers"),
                        subtitle: l10n("残留配置 · 孤立数据 · 废弃容器", "Leftover Configs · Orphan Files · Containers"),
                        sizeString: cardSizeString(for: leftoversSize),
                        xOffset: -8,
                        yOffset: 0
                    ) {
                        activeCategoryFilter = [.orphanLeftovers]
                        activeDetailTitle = l10n("应用卸载残留明细", "Application Leftovers Details")
                        if viewModel.scanResult == nil && !viewModel.isScanning {
                            viewModel.startScan()
                        }
                        showingScanDetail = true
                    }
                }
                .frame(width: 252)
            }
            .frame(maxWidth: 860)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)

            Spacer(minLength: 8)

            // Bottom Clickable Full Scan / List Entrance
            Button(action: {
                activeCategoryFilter = nil
                activeDetailTitle = l10n("扫描详情", "Scan Details")
                if viewModel.scanResult == nil && !viewModel.isScanning {
                    viewModel.startScan()
                }
                showingScanDetail = true
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "38BDF8"))
                        .frame(width: 6.5, height: 6.5)
                        .shadow(color: Color(hex: "38BDF8"), radius: 2)

                    Text(l10n("查看扫描详情 ↗", "View Scan Details ↗"))
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
                                            Color(hex: "38BDF8").opacity(0.4),
                                            Color(hex: "818CF8").opacity(0.2)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                        .shadow(color: Color(hex: "38BDF8").opacity(0.08), radius: 3, x: 0, y: 1)
                )
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .padding(.bottom, 14)
        }
    }

    // MARK: - Grand 3D Luminous Aqua Glass Sphere Bubble (三态自洽一体化核心球)
    private var luminousAquaGlassSphereHero: some View {
        Button(action: {
            if viewModel.isScanning || viewModel.isCleaning {
                return
            }
            if viewModel.scanResult != nil && !viewModel.selectedItemIds.isEmpty {
                viewModel.executeClean()
            } else {
                viewModel.startScan()
            }
        }) {
            ZStack {
                // Layer 1: Ambient Multi-Spectral Outer Bloom (Outer Glow Aura, 280pt)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "C084FC").opacity(isOrbHovered ? 0.45 : 0.30),
                                Color(hex: "38BDF8").opacity(isOrbHovered ? 0.35 : 0.22),
                                Color(hex: "6366F1").opacity(0.12),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: isOrbHovered ? 20 : 15)

                // (Note: Symmetric 8 dots & dashed orbit removed per design requirement)

                // Layer 2: Glass Sphere Core Body with Liquid Wave at bottom
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)

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

                    // Internal Dynamic Liquid Wave (strictly bottom 36pt, zero text occlusion)
                    VStack {
                        Spacer()
                        liquidWaveMembrane
                            .frame(height: 36)
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(Circle())

                // Layer 3: 3D Iridescent Optical Glass Rim Border
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
                        lineWidth: isOrbHovered ? 2.8 : 2.2
                    )
                    .frame(width: 240, height: 240)
                    .shadow(color: Color(hex: "38BDF8").opacity(isOrbHovered ? 0.70 : 0.45), radius: isOrbHovered ? 15 : 11, x: 0, y: 0)

                // Layer 4: Top-Left Crescent Specular Shine (光斑高光)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.2), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 26)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -62, y: -62)

                // Layer 5: Center Big Numbers & Typography Inside the Sphere (自洽三态一体化)
                VStack(spacing: 5) {
                    if viewModel.isScanning || viewModel.isCleaning {
                        ProgressView()
                            .scaleEffect(1.15)
                            .padding(.bottom, 4)

                        Text(l10n("正在全盘智能扫描...", "Scanning Full Disk..."))
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "38BDF8"))

                        Text(l10n("排查系统垃圾、大文件与残留", "Analyzing junk & leftovers"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if viewModel.scanResult != nil && !viewModel.selectedItemIds.isEmpty {
                        // 扫描完成待清理态: 大字容量 + 发光纯净字效
                        Text(viewModel.selectedFormattedSize)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .shadow(color: Color(hex: "38BDF8").opacity(0.45), radius: 6, x: 0, y: 2)

                        Text(l10n("可安全清理", "Safe to Clean"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11.5, weight: .bold))
                            Text(l10n("立即清理", "Clean Now"))
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8"), Color(hex: "818CF8"), Color(hex: "C084FC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(hex: "38BDF8").opacity(0.45), radius: 6)
                        .padding(.top, 2)
                        .scaleEffect(isOrbHovered ? 1.05 : 1.0)
                    } else if viewModel.scanResult != nil {
                        // 清理完成 / 系统良好态
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "34D399"), Color(hex: "059669")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "10B981").opacity(0.40), radius: 6)
                            .padding(.bottom, 2)

                        Text(l10n("系统状态良好", "System Optimal"))
                            .font(.system(size: 17.5, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text(l10n("重新扫描", "Rescan"))
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "38BDF8"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "38BDF8").opacity(0.15)))
                        .padding(.top, 2)
                    } else {
                        // 未扫描初始态 (使用放大镜图标，大方专业)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "38BDF8"), Color(hex: "818CF8")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "38BDF8").opacity(0.40), radius: 6)
                            .padding(.bottom, 2)

                        Text(l10n("开始扫描", "Start Scan"))
                            .font(.system(size: 18.5, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(l10n("全盘智能扫描", "Full System Scan"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 280, height: 280)
            .aspectRatio(1.0, contentMode: .fit)
            .scaleEffect(isOrbHovered ? 1.025 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOrbHovered)
        }
        .buttonStyle(PureButtonStyle())
        .focusable(false)
        .focusEffectDisabled()
        .onHover { isOrbHovered = $0 }
    }

    // High-Performance Liquid Horizon Glass Caustics (Zero frame invalidation)
    private var liquidWaveMembrane: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "38BDF8").opacity(0.35),
                            Color(hex: "818CF8").opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 260, height: 50)
                .offset(y: 12)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "818CF8").opacity(0.25),
                            Color(hex: "C084FC").opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 230, height: 44)
                .offset(y: 16)
        }
    }

    // MARK: - Orbiting Glass Bubble Pod (围绕大气泡的轻盈小气泡卡片)
    private func orbitingGlassBubblePod(
        icon: String,
        iconBgGradient: [Color],
        title: String,
        subtitle: String,
        sizeString: String,
        xOffset: CGFloat = 0,
        yOffset: CGFloat = 0,
        onAction: @escaping () -> Void
    ) -> some View {
        Button(action: onAction) {
            HStack(spacing: 12) {
                // Frosted Orb Icon Badge (Scaled to 40x40)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconBgGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: iconBgGradient.first?.opacity(0.35) ?? Color.clear, radius: 5, x: 0, y: 2)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2.5) {
                    Text(sizeString)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.65),
                                        Color(hex: "38BDF8").opacity(0.20),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.05), radius: 6, x: 0, y: 2)
            )
            .offset(x: xOffset, y: yOffset)
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
                        Text(l10n("返回", "Back"))
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
                        Text(l10n("清理所选 (\(displayedSelectedSizeString))", "Clean Selected (\(displayedSelectedSizeString))"))
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
                    if viewModel.isScanning || viewModel.isCleaning {
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
                                Text(l10n("未发现垃圾残留", "No Junk Files Found"))
                                    .font(.system(size: 14, weight: .bold))
                                Text(l10n("系统保持良好，无需额外清理", "System is clean & optimal."))
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
                .overlay(
            Group {
                if viewModel.showingCleanErrorsSheet, let report = viewModel.lastCleanReport {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                            .onTapGesture { viewModel.showingCleanErrorsSheet = false }
                        
                        CleanErrorsSheetView(report: report) {
                            viewModel.showingCleanErrorsSheet = false
                        }
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 20)
                        .padding(40)
                    }
                }
            }
        )
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
                    Text(l10n("在访达中显示", "Show in Finder"))
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

// MARK: - Clean Errors Detail Sheet
struct CleanErrorsSheetView: View {
    let report: CleanExecutionReport
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "F59E0B"))
                        .font(.system(size: 14))
                    Text(l10n("未清理项目明细 (\(report.failedCount) 项)", "Skipped Items Detail (\(report.failedCount) items)"))
                        .font(.system(size: 14, weight: .bold))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)

            Divider().opacity(0.2)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(report.errors.enumerated()), id: \.offset) { _, err in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color(hex: "F59E0B"))
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)

                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineSpacing(2)

                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.06)))
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 320)

            Divider().opacity(0.2)

            HStack {
                Text(l10n("系统核心受保护文件或正被运行中软件占用的文件已被安全跳过，以保障系统稳定。", "System-protected files or files in use were safely skipped to ensure stability."))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button(l10n("我知道了", "Got it"), action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(14)
        }
        .frame(width: 480)
        
    }
}




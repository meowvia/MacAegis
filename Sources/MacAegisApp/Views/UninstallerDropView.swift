import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MacAegisCore

public struct UninstallerDropView: View {
    @ObservedObject var viewModel: UninstallerViewModel
    var onBack: (() -> Void)? = nil
    @State private var isTargeted: Bool = false

    public init(viewModel: UninstallerViewModel, onBack: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            if viewModel.isAnalyzing {
                VStack(spacing: 14) {
                    Spacer()
                    ProgressView().scaleEffect(1.1)
                    Text("正在深度分析应用关联的配置文件与沙盒支持文件...")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if let bundle = viewModel.selectedBundle {
                appDetailShowcase(bundle: bundle)
            } else {
                fullWidthBrowserView
            }

            // Success Toast Banner
            if let toast = viewModel.toastMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { viewModel.toastMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .studioCard(cornerRadius: 10, isSelected: true)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        .background(MacAegisTheme.canvasBackground.ignoresSafeArea())
        .onAppear {
            viewModel.loadInstalledApps()
        }
        .alert("卸载提示", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.alertMessage = nil }
        } message: {
            if let msg = viewModel.alertMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Full Width Apps Browser + Drop Zone
    private var fullWidthBrowserView: some View {
        VStack(spacing: 0) {
            // Header Bar: App Count Badge & Search Bar Only
            HStack(spacing: 14) {
                // App Count Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text(l10n("\(viewModel.filteredApps.count) 个应用", "\(viewModel.filteredApps.count) Apps"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                Spacer()

                // Top Right Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField(l10n("搜索应用...", "Search apps..."), text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                        .focusEffectDisabled()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 200)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 10) {
                    // Table Header Row
                    HStack {
                        Text(l10n("应用名称", "Application"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(l10n("大小", "Size"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        Text(l10n("操作", "Action"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                    // Applications List (Strict 0-9, A-Z natural sort)
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.filteredApps, id: \.bundleURL) { app in
                            appRow(app: app)
                        }
                    }
                }
                .padding(24)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        viewModel.analyzeApp(url: url)
                    }
                }
            }
            return true
        }
    }

    private func appRow(app: AppDetector.InstalledApp) -> some View {
        let isExpanded = viewModel.isExpanded(url: app.bundleURL)
        let isAnalyzing = viewModel.analyzingAppUrls.contains(app.bundleURL)
        let bundle = viewModel.analyzedBundles[app.bundleURL]

        return VStack(spacing: 0) {
            // Main App Row Header (Clickable to Toggle Expansion)
            Button(action: {
                viewModel.toggleAppExpansion(url: app.bundleURL)
            }) {
                HStack(spacing: 12) {
                    // Expand Chevron Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 12)

                    // App Icon Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "app.fill")
                            .foregroundColor(Color.blue)
                            .font(.system(size: 15))
                    }

                    // App Name & Bundle ID
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(app.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            if isExpanded {
                                Text(l10n("明细已展开", "Expanded"))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(Color.blue)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                            }
                        }
                        if let bid = app.bundleId {
                            Text(bid)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // App Size (Dynamic live sum when analyzed)
                    Text(viewModel.appSize(for: app))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    // Finder Reveal of .app
                    Button(action: {
                        viewModel.revealSubItemInFinder(path: app.bundleURL.path)
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                    .help(l10n("在访达中显示主程序包", "Reveal in Finder"))

                    // Uninstall Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.analyzeApp(url: app.bundleURL)
                        }
                    }) {
                        Text(l10n("卸载", "Uninstall"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.12)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                    .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()

            // Inline Expanded Details Breakdown Card
            if isExpanded {
                Divider().opacity(0.2)
                VStack(spacing: 6) {
                    if isAnalyzing && bundle == nil {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text(l10n("正在深度扫描此应用的关联数据与残留...", "Scanning associated files..."))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 14)
                    } else if let bundle = bundle {
                        VStack(spacing: 4) {
                            ForEach(bundle.associatedItems) { item in
                                inlineSubItemRow(item: item)
                            }
                        }
                        .padding(.top, 4)

                        // Quick Action Footer inside expanded view
                        HStack {
                            Text(l10n("包含 \(bundle.associatedItems.count) 项关联目录 · 共计 \(bundle.formattedTotalSize)", "Contains \(bundle.associatedItems.count) items · Total \(bundle.formattedTotalSize)"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    viewModel.analyzeApp(url: app.bundleURL)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash.fill")
                                    Text(l10n("进入卸载确认", "Review & Uninstall"))
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(MacAegisTheme.roseGradient)
                                )
                            }
                            .buttonStyle(PureButtonStyle())
                            .focusable(false)
                            .focusEffectDisabled()
                        }
                        .padding(.top, 6)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .background(Color.secondary.opacity(0.03))
            }
        }
        .studioCard(cornerRadius: 8)
    }

    private func inlineSubItemRow(item: CleanItem) -> some View {
        HStack(spacing: 8) {
            // Category Icon
            Image(systemName: iconForSubItem(path: item.path))
                .font(.system(size: 10))
                .foregroundColor(colorForSubItem(path: item.path))
                .frame(width: 14)

            // Humanized Name + Category Badge
            Text(humanizedCategoryName(for: item))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)

            // Truncated Path
            Text(item.path)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Finder Location Pin Button
            Button(action: {
                viewModel.revealSubItemInFinder(path: item.path)
            }) {
                HStack(spacing: 2) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 8))
                    Text(l10n("定位", "Reveal"))
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.08)))
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .help(l10n("在访达中定位此文件夹", "Reveal in Finder"))

            // Size
            Text(item.formattedSize)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.04)))
    }

    private func iconForSubItem(path: String) -> String {
        if path.hasSuffix(".app") { return "app.fill" }
        if path.contains("Application Support") || path.contains("Containers") || path.contains("Group Containers") { return "folder.fill" }
        if path.contains("Caches") || path.contains("WebKit") || path.contains("HTTPStorages") { return "bolt.fill" }
        if path.contains("Preferences") { return "gearshape.fill" }
        if path.contains("LaunchAgents") || path.contains("LaunchDaemons") { return "paperplane.fill" }
        if path.contains("Logs") { return "doc.text.fill" }
        return "folder"
    }

    private func colorForSubItem(path: String) -> Color {
        if path.hasSuffix(".app") { return Color.blue }
        if path.contains("Containers") || path.contains("Group Containers") || path.contains("Application Support") { return Color.purple }
        if path.contains("Caches") || path.contains("WebKit") { return Color.orange }
        if path.contains("Preferences") { return Color(hex: "94A3B8") }
        if path.contains("LaunchAgents") || path.contains("LaunchDaemons") { return Color(hex: "10B981") }
        return Color.secondary
    }

    private func humanizedCategoryName(for item: CleanItem) -> String {
        let path = item.path
        if path.hasSuffix(".app") { return l10n("主程序包", "App Bundle") }
        if path.contains("Containers") { return l10n("沙盒隔离容器", "Sandbox Container") }
        if path.contains("Group Containers") { return l10n("共享数据组", "Group Container") }
        if path.contains("Application Support") { return l10n("应用支持数据", "Application Support") }
        if path.contains("Caches") || path.contains("WebKit") || path.contains("HTTPStorages") { return l10n("运行缓存", "Caches") }
        if path.contains("Preferences") { return l10n("偏好设置", "Preferences") }
        if path.contains("LaunchAgents") || path.contains("LaunchDaemons") { return l10n("自启服务", "Launch Agent") }
        if path.contains("Logs") { return l10n("运行日志", "Logs") }
        if path.contains("Saved Application State") { return l10n("窗口快照", "Saved State") }
        return item.name
    }

    // MARK: - App Detail Showcase
    private func appDetailShowcase(bundle: AppUninstallBundle) -> some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 14) {
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        viewModel.selectedBundle = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(l10n("返回列表", "Back"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.1)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "app.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.blue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(bundle.appName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text(l10n("共 \(bundle.associatedItems.count) 项关联文件 · 总计: \(bundle.formattedTotalSize)", "\(bundle.associatedItems.count) associated items · Total: \(bundle.formattedTotalSize)"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { viewModel.executeUninstall() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text(l10n("彻底卸载 (\(viewModel.formattedSelectedSize))", "Uninstall (\(viewModel.formattedSelectedSize))"))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(MacAegisTheme.roseGradient)
                            .shadow(color: Color(hex: "F43F5E").opacity(0.35), radius: 6, x: 0, y: 2)
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
                .disabled(viewModel.selectedItemIds.isEmpty || viewModel.isUninstalling)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))

            Divider().opacity(0.3)

            // Detailed Associated Files List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(bundle.associatedItems) { item in
                        HStack(spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { viewModel.selectedItemIds.contains(item.id) },
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
                                }
                                Text(item.path)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Text(item.formattedSize)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .studioCard(cornerRadius: 6)
                    }
                }
                .padding(14)
            }
        }
    }
}

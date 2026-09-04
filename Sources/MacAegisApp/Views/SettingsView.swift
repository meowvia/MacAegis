import SwiftUI
import ServiceManagement
import MacAegisCore

public struct SettingsView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @AppStorage("cleanToTrash") private var cleanToTrash: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("tempUnitCelsius") private var tempUnitCelsius: Bool = true
    @AppStorage("menuBarMonitor") private var menuBarMonitor: Bool = true
    @AppStorage("trashWatcher") private var trashWatcher: Bool = true
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("keepInMemoryOnClose") private var keepInMemoryOnClose: Bool = true

    public var onDismiss: (() -> Void)? = nil

    private let controlWidth: CGFloat = 210

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar (Standard macOS Top-Left Close Button)
            HStack(spacing: 12) {
                Button(action: { onDismiss?() }) {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 13, height: 13)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.black.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                .help(l10n("关闭设置", "Close Settings"))

                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text(l10n("偏好设置", "Preferences"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.25)

            ScrollView {
                VStack(spacing: 16) {
                    // 1. 通用与外观 (General & Appearance)
                    settingsSection(title: l10n("通用与外观", "General & Appearance"), icon: "macwindow", color: Color(hex: "38BDF8")) {
                        // Appearance
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("外观模式", "Appearance Mode"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("自动跟随系统、浅色或深色", "Match system, light or dark mode"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $appearanceMode) {
                                Text(l10n("跟随系统", "System")).tag(AppearanceMode.system)
                                Text(l10n("浅色", "Light")).tag(AppearanceMode.light)
                                Text(l10n("深色", "Dark")).tag(AppearanceMode.dark)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)
                        }

                        Divider().opacity(0.18)

                        // Interface Language
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("界面显示语言", "Interface Language"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("切换应用语言（立即生效）", "Choose language (takes effect immediately)"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $loc.appLanguage) {
                                Text("简体中文").tag(AppLanguage.zh)
                                Text("English").tag(AppLanguage.en)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)

                        }
                    }

                    // 2. 硬件监测与单位 (Hardware & Telemetry)
                    settingsSection(title: l10n("硬件监测与单位", "Hardware & Telemetry"), icon: "gauge.medium", color: Color(hex: "06B6D4")) {
                        // Temperature Unit
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("温度显示单位", "Temperature Unit"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("系统监测与状态栏的温度读数单位", "Thermal reading unit across app and menu bar"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $tempUnitCelsius) {
                                Text(l10n("摄氏度 (℃)", "Celsius (℃)")).tag(true)
                                Text(l10n("华氏度 (℉)", "Fahrenheit (℉)")).tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)

                        }

                        Divider().opacity(0.18)

                        // Menu Bar Monitor
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("菜单栏实时监控", "Menu Bar Telemetry"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("在顶部菜单栏实时显示网速、温度与芯片负载", "Show network speed, temp and CPU load in menu bar"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Toggle("", isOn: $menuBarMonitor)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }

                    // 3. 清理与系统保护 (Cleanup & System Protection)
                    settingsSection(title: l10n("清理与系统保护", "Cleanup & Protection"), icon: "shield.fill", color: Color(hex: "10B981")) {
                        // Clean method
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("默认清理方式", "Default Clean Method"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("移入废纸篓可在误删时随时还原", "Moving to Trash allows quick restoration"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $cleanToTrash) {
                                Text(l10n("移入废纸篓 (推荐)", "Trash (Recommended)")).tag(true)
                                Text(l10n("彻底永久删除", "Permanent Delete")).tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)

                        }

                        Divider().opacity(0.18)

                        // Trash Watcher
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("废纸篓残留监听", "Trash Leftovers Sentinel"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("在访达删除应用时，自动提示清理残留配置文件", "Notify to clean leftovers when apps are trashed"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Toggle("", isOn: $trashWatcher)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        Divider().opacity(0.18)

                        // Launch at Login
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("开机自动启动", "Launch at Login"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("在系统登录时在后台启动 MacAegis 常驻服务", "Start MacAegis in background at system login"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        Divider().opacity(0.18)

                        // Close Window Action
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("关闭主窗口 (Cmd+W)", "Close Window Action"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("点击左上角红色关闭按钮时的行为", "Behavior when red close button is clicked"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $keepInMemoryOnClose) {
                                Text(l10n("保持后台运行", "Keep in Menu Bar")).tag(true)
                                Text(l10n("退出应用", "Quit MacAegis")).tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)

                        }

                        Divider().opacity(0.18)

                        // Full Disk Access (FDA)
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("完全磁盘访问权限 (FDA)", "Full Disk Access (FDA)"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("授予权限可深度扫描系统日志与沙盒残留", "Grant permission to deep scan logs & sandboxes"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            if FullDiskAccessHelper.shared.hasFullDiskAccess() {
                                HStack(spacing: 4) {
                                    Circle().fill(Color(hex: "10B981")).frame(width: 6, height: 6)
                                    Text(l10n("已授权", "Granted"))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: "10B981"))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "10B981").opacity(0.12)))
                            } else {
                                Button(action: {
                                    FullDiskAccessHelper.shared.openSystemSettings()
                                }) {
                                    HStack(spacing: 4) {
                                        Text(l10n("去授权", "Authorize"))
                                        Image(systemName: "arrow.up.forward.app")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(hex: "38BDF8")))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider().opacity(0.18)

                        // App Management Permission
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("App 管理权限 (App Management)", "App Management Permission"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("允许 MacAegis 移动或彻底卸载 /Applications 中的受保护应用", "Allows MacAegis to move or uninstall apps in /Applications"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Button(action: {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(l10n("去设置", "Configure"))
                                    Image(systemName: "arrow.up.forward.app")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "38BDF8")))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 4. 隐私政策与安全承诺 (Privacy & Security Commitment)
                    settingsSection(title: l10n("隐私政策与安全承诺", "Privacy & Security Policy"), icon: "lock.shield.fill", color: Color(hex: "10B981")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Color(hex: "10B981"))
                                    .font(.system(size: 12))
                                Text(l10n("100% 纯本地离线运行", "100% Offline & Local Execution"))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(l10n("MacAegis 所有磁盘扫描、空间清理与隐匿锁定操作均在你的 Mac 本地执行，不含任何远程分析或云端上传，零外网数据通信。", "All scans, cleaning, and concealment operations run locally on your Mac without remote analytics or cloud transmission."))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Divider().opacity(0.15)

                            HStack(spacing: 6) {
                                Image(systemName: "key.fill")
                                    .foregroundColor(Color(hex: "38BDF8"))
                                    .font(.system(size: 12))
                                Text(l10n("钥匙串与硬件安全集成", "macOS Keychain & Hardware Isolation"))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(l10n("隐私保险箱主密码与数据密钥通过 macOS 原生钥匙串与 PBKDF2 10万次哈希存储，受 Apple 系统安全机制严格保护。", "Master passwords and encryption keys are stored via macOS native Keychain with 100,000 iterations PBKDF2."))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }


            Divider().opacity(0.25)

            // Bottom Bar
            HStack {
                HStack(spacing: 8) {
                    Text("\(AppConfig.appName) v\(AppConfig.appVersion)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.5))
                    Button(action: {
                        Task {
                            if let update = await UpdateChecker.shared.checkForUpdates(), update.hasUpdate {
                                if let urlStr = update.downloadURL, let url = URL(string: urlStr) {
                                    NSWorkspace.shared.open(url)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let alert = NSAlert()
                                    alert.messageText = l10n("当前已是最新版本", "You're up to date")
                                    alert.informativeText = l10n("MacAegis v\(AppConfig.appVersion) 已是最新稳定版。", "MacAegis v\(AppConfig.appVersion) is the latest release.")
                                    alert.addButton(withTitle: l10n("好", "OK"))
                                    alert.runModal()
                                }
                            }
                        }
                    }) {
                        Text(l10n("检查更新", "Check for Updates"))
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "38BDF8"))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button(l10n("完成", "Done")) {
                    onDismiss?()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
        .frame(width: 560, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)

        .onChange(of: launchAtLogin) { _, newValue in
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Launch at login error: \(error)")
                }
            }
        }
        .onChange(of: menuBarMonitor) { _, newValue in
            StatusBarController.shared.updateVisibility(enabled: newValue)
        }
        .onChange(of: trashWatcher) { _, newValue in
            if newValue {
                TrashWatcherService.shared.startWatching()
            } else {
                TrashWatcherService.shared.stopWatching()
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 10) {
                content()
            }
            .padding(14)
            .studioCard(cornerRadius: 10)
        }
    }
}

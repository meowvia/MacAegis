import SwiftUI
import MacAegisCore

public struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.zh.rawValue
    @AppStorage("cleanToTrash") private var cleanToTrash: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("tempUnitCelsius") private var tempUnitCelsius: Bool = true
    @AppStorage("menuBarMonitor") private var menuBarMonitor: Bool = true
    @AppStorage("trashWatcher") private var trashWatcher: Bool = true
    @AppStorage("keepInMemoryOnClose") private var keepInMemoryOnClose: Bool = true

    @Environment(\.dismiss) private var dismiss

    private let controlWidth: CGFloat = 210

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text(l10n("偏好设置", "Preferences"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.25)

            ScrollView {
                VStack(spacing: 16) {
                    // 1. 语言设置 (Language Preferences)
                    settingsSection(title: l10n("语言设置", "Language Preferences"), icon: "globe", color: Color(hex: "38BDF8")) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("界面显示语言", "Interface Language"))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(l10n("切换应用界面语言（立即生效）", "Choose language (takes effect immediately)"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 16)

                            Picker("", selection: $appLanguage) {
                                Text(l10n("简体中文 (Chinese)", "Simplified Chinese")).tag(AppLanguage.zh.rawValue)
                                Text("English").tag(AppLanguage.en.rawValue)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: controlWidth)
                            .id("lang_picker_\(appLanguage)")
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
                            .id("temp_picker_\(appLanguage)")
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
                            .id("clean_mode_\(appLanguage)")
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
                            .id("close_action_\(appLanguage)")
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
                    }
                }
                .padding(20)
            }
            .id("settings_scroll_\(appLanguage)")

            Divider().opacity(0.25)

            // Bottom Bar
            HStack {
                HStack(spacing: 6) {
                    Text("\(AppConfig.appName) v\(AppConfig.appVersion)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.5))
                    Link("GitHub", destination: URL(string: "https://github.com/meowvia/MacAegis")!)
                        .font(.system(size: 11))
                }
                Spacer()
                Button(l10n("完成", "Done")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
        .frame(width: 540, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .id("settings_root_\(appLanguage)")
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

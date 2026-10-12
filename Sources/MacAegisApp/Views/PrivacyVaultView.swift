import SwiftUI
import MacAegisCore

/// Open-Core placeholder view for the proprietary Privacy Vault component.
/// The full proprietary Privacy Vault implementation is distributed exclusively in official pre-compiled DMG releases.
public struct PrivacyVaultView: View {
    @ObservedObject var viewModel: PrivacyVaultViewModel
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: PrivacyVaultViewModel = PrivacyVaultViewModel(), onBack: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header / Back navigation
            HStack {
                Button(action: { onBack?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text(l10n("返回", "Back"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer()

            // Open-Core Reservation Card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "38BDF8").opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8"), Color(hex: "818CF8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(l10n("独立空间 (Privacy Vault)", "Privacy Vault"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(l10n("专有闭源技术保留组件", "Proprietary Closed-Source Component"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "38BDF8"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "38BDF8").opacity(0.12))
                    )

                Text(l10n(
                    "MacAegis 核心清理与卸载引擎完全开源 (GPL-3.0)。\n「独立空间」文件原地隐匿引擎、4KB 数据重混算法及 Secure Enclave 硬件安全触控 ID 集成为专有闭源资产，不包含在开源代码库中。\n\n该功能已在官方编译版中免费提供，如需体验请下载官方正式安装镜像。",
                    "MacAegis cleaning and uninstaller engines are 100% open-source (GPL-3.0).\nThe proprietary Privacy Vault in-place concealment engine, 4KB scrambler, and Secure Enclave Touch ID integration are excluded from the open-source repository.\n\nThis feature is available free of charge in the official pre-compiled DMG release."
                ))
                .font(.system(size: 12.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 440)

                Button(action: {
                    if let url = URL(string: "https://github.com/meowvia/MacAegis/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n("获取官方预编译完整版", "Download Official Pre-compiled Release"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.secondary.opacity(0.08) : Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 0.8)
                    )
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

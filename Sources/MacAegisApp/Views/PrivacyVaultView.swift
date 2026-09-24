import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MacAegisCore

private final class DroppedURLBox: @unchecked Sendable {
    private var urls: [URL] = []
    private let lock = NSLock()

    func append(_ url: URL) {
        lock.lock()
        urls.append(url)
        lock.unlock()
    }

    func retrieve() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        return urls
    }
}

public struct VaultShakeEffect: GeometryEffect {
    public var amount: CGFloat = 7
    public var shakesPerUnit: CGFloat = 4
    public var animatableData: CGFloat

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0
        ))
    }
}

public struct PrivacyVaultView: View {
    @StateObject private var viewModel = PrivacyVaultViewModel()
    var onBack: (() -> Void)? = nil
    @State private var isTargeted: Bool = false

    // Password Setup States
    @State private var newPasswordInput: String = ""
    @State private var confirmPasswordInput: String = ""
    @State private var passwordHintInput: String = ""
    @State private var isShowingRecoveryKey: Bool = false
    @State private var isRecoveryCodeRevealed: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    public init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            // Cosmic Liquid Glass Backdrop (Matching DashboardView)
            cosmicLiquidGlassBackdrop

            if !viewModel.hasMasterPassword {
                firstTimeSetupContent
            } else if viewModel.isUnlocked {
                unlockedVaultContent
            } else {
                lockedGateContent
            }

            // Floating Toast Notification (Positioned at bottom center, exactly 76px above dock)
            if let toast = viewModel.toastMessage {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .studioCard(cornerRadius: 12, isSelected: true)
                    .padding(.bottom, 76)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(500)
            }

            // Confirm Batch Remove Modal Overlay
            if viewModel.isConfirmingBatchRemove {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.isConfirmingBatchRemove = false
                            }
                        }

                    confirmBatchRemoveCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .zIndex(1000)
            }

            // Change Password Modal Overlay
            if viewModel.isChangingPassword {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.isChangingPassword = false
                            }
                        }

                    changePasswordCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .zIndex(1000)
            }

            // Recover With Code Modal Overlay
            if viewModel.isRecoveringWithCode {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.isRecoveringWithCode = false
                            }
                        }

                    recoverWithCodeCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .zIndex(1000)
            }

            // Show Recovery Key Modal Overlay
            if isShowingRecoveryKey {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isShowingRecoveryKey = false
                            }
                        }

                    showRecoveryKeyCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .zIndex(1000)
            }

            // User Notice Modal Overlay
            if viewModel.isShowingUserNotice {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if viewModel.userNoticeCountdown <= 0 {
                                viewModel.dismissUserNotice()
                            }
                        }

                    userNoticeModalCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .zIndex(1000)
            }
        }
    }

    // MARK: - Confirm Batch Remove Card View
    private var confirmBatchRemoveCard: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.system(size: 14))
                    )

                Text(l10n("确认批量解除保护？", "Confirm Remove Protection?"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
            }

            let validCount = viewModel.items.filter { viewModel.selectedItemIds.contains($0.id) }.count
            Text(l10n("即将解除选中的 \(validCount) 个项目。解除后项目将从列表中移出并在访达中恢复正常可见。", "The selected \(validCount) items will be removed from the list and made visible in Finder."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button(l10n("取消", "Cancel")) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isConfirmingBatchRemove = false
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    viewModel.batchRemoveProtectionSelected()
                }) {
                    Text(l10n("确认解除", "Remove Protection"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    // MARK: - Change Password Card View
    private var changePasswordCard: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isChangingPassword = false
                    }
                }) {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .black))
                                .foregroundColor(.black.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color(hex: "38BDF8"))
                        .font(.system(size: 13))
                    Text(l10n("修改空间主密码", "Change Master Password"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
            }

            Divider().opacity(0.2)

            if let err = viewModel.changePasswordErrorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "EF4444").opacity(0.12)))
            }

            VStack(spacing: 10) {
                SecureField(l10n("当前旧密码", "Current password"), text: $viewModel.oldPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                SecureField(l10n("新主密码 (至少 6 位)", "New password (6+ chars)"), text: $viewModel.newPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                SecureField(l10n("确认新密码", "Confirm new password"), text: $viewModel.confirmNewPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                TextField(l10n("新密码提示 (选填)", "New password hint (optional)"), text: $viewModel.newPasswordHintInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
            }
            .frame(width: 320)

            HStack(spacing: 12) {
                Button(l10n("取消", "Cancel")) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isChangingPassword = false
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    _ = viewModel.executeChangePassword()
                }) {
                    Text(l10n("确认修改", "Confirm Change"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
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
                .disabled(viewModel.oldPasswordInput.isEmpty || viewModel.newPasswordInput.isEmpty)
                .opacity(viewModel.oldPasswordInput.isEmpty || viewModel.newPasswordInput.isEmpty ? 0.5 : 1.0)
            }
            .frame(width: 320)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    // MARK: - Recover With Code Card View
    private var recoverWithCodeCard: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isRecoveringWithCode = false
                    }
                }) {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .black))
                                .foregroundColor(.black.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(Color(hex: "10B981"))
                        .font(.system(size: 13))
                    Text(l10n("使用恢复密钥找回", "Recover with Recovery Key"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
            }

            Divider().opacity(0.2)

            Text(l10n("输入 64 位恢复密钥重置主密码并恢复访问权限", "Enter your 64-character recovery key to reset master password and regain access."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(width: 320)

            if let err = viewModel.recoveryErrorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "EF4444").opacity(0.12)))
            }

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    if isRecoveryCodeRevealed {
                        TextField(l10n("AEGIS-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX", "Recovery Key"), text: $viewModel.recoveryCodeInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                    } else {
                        SecureField(l10n("AEGIS-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX", "Recovery Key"), text: $viewModel.recoveryCodeInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    Button(action: { isRecoveryCodeRevealed.toggle() }) {
                        Image(systemName: isRecoveryCodeRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                SecureField(l10n("设置新密码 (至少 6 位)", "New master password (6+ chars)"), text: $viewModel.recoveryNewPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))

                SecureField(l10n("确认新密码", "Confirm new password"), text: $viewModel.recoveryConfirmPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
            }
            .frame(width: 320)

            HStack(spacing: 12) {
                Button(l10n("取消", "Cancel")) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isRecoveringWithCode = false
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    _ = viewModel.executeRecoverWithCode()
                }) {
                    Text(l10n("恢复并重设密码", "Recover & Reset"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "10B981"), Color(hex: "059669")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .disabled(viewModel.recoveryCodeInput.isEmpty || viewModel.recoveryNewPasswordInput.isEmpty)
                .opacity(viewModel.recoveryCodeInput.isEmpty || viewModel.recoveryNewPasswordInput.isEmpty ? 0.5 : 1.0)
            }
            .frame(width: 320)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    // MARK: - Show Recovery Key Card View
    private var showRecoveryKeyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowingRecoveryKey = false
                    }
                }) {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .black))
                                .foregroundColor(.black.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .foregroundColor(Color(hex: "38BDF8"))
                        .font(.system(size: 13))
                    Text(l10n("灾难恢复密钥", "Disaster Recovery Key"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
            }

            Divider().opacity(0.2)

            Text(l10n("这是你独立空间的恢复密钥，请妥善保存在安全的离线地点。若遗忘主密码，可通过此密钥重置访问权限。", "This is your recovery key. Please keep it in a secure offline location. If you forget your master password, use this key to regain access."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(width: 330)

            if let code = viewModel.masterRecoveryCode {
                Text(code)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(width: 330)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                Spacer()

                Button(action: {
                    if let code = viewModel.masterRecoveryCode {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(code, forType: .string)
                        viewModel.showToast(l10n("恢复密钥已复制到剪贴板 📋", "Recovery key copied to clipboard 📋"))
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowingRecoveryKey = false
                        }
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc.fill")
                        Text(l10n("复制恢复密钥", "Copy Recovery Key"))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "0284C7")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    // MARK: - User Notice Modal Card
    private var userNoticeModalCard: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text(l10n("使用须知", "User Notice"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                if viewModel.userNoticeCountdown <= 0 {
                    Button(action: {
                        viewModel.dismissUserNotice()
                    }) {
                        Circle()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(l10n("欢迎使用 MacAegis 独立空间功能。为保障正常使用体验，请在使用前知悉以下事项：", "Welcome to MacAegis Private Space. Please note the following before use:"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)

                    // Clause 1
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n("1. 主密码与恢复密钥保管", "1. Safely Keep Master Password & Recovery Key"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        Text(l10n("• 系统采用本地离线处理机制，不上传任何用户数据；\n• 初次设置后请妥善备份专属恢复密钥；\n• 若遗忘主密码，恢复密钥是重置访问凭据的唯一途径。", "• Operates entirely offline without cloud upload.\n• Please back up your unique recovery key after initial setup.\n• The recovery key is the sole credential to regain access if you forget your password."))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }

                    // Clause 2
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n("2. 避免外部下载直接写入锁定目录", "2. Avoid Setting Download Path to Locked Folders"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        Text(l10n("• 处于锁定隐藏状态的目录可能导致外部应用写入异常；\n• 请勿将浏览器或下载工具的默认保存路径直接设置为受保护目录；\n• 建议文件下载完成后再移入本空间进行管理。", "• Folders in locked hidden status may cause write errors for external apps.\n• Do not set download tools' default save location directly to a locked folder.\n• Move files into Private Space after downloading completes."))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }

                    // Clause 3
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n("3. 云盘同步目录提示", "3. Cloud Sync Folder Notice"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        Text(l10n("• 为避免与云盘同步服务发生冲突，建议对本地磁盘文件进行管理；\n• 如需保护云盘中的文件，建议先拷贝至本地磁盘后再添加。", "• To prevent conflicts with cloud synchronization services, manage local files.\n• Copy cloud-stored files to local disk before managing."))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }

                    // Clause 4
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n("4. 本地原位处理说明", "4. Local In-Place Processing"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        Text(l10n("• 文件在原始存储路径进行属性调整，不产生额外数据副本；\n• 锁定与恢复操作直接作用于本地文件系统。", "• Adjusts file visibility directly at original paths without redundant duplicates.\n• Conceal and reveal operations apply locally to the filesystem."))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)

            let isCountdownActive = viewModel.userNoticeCountdown > 0
            Button(action: {
                if !isCountdownActive {
                    viewModel.dismissUserNotice()
                }
            }) {
                HStack(spacing: 6) {
                    if isCountdownActive {
                        Text(l10n("我已阅读并知晓 (\(viewModel.userNoticeCountdown)s)", "I have read and understood (\(viewModel.userNoticeCountdown)s)"))
                    } else {
                        Text(l10n("我已阅读并知晓", "I have read and understood"))
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isCountdownActive ? Color.white.opacity(0.45) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isCountdownActive
                                ? LinearGradient(
                                    colors: [Color.secondary.opacity(0.20), Color.secondary.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color(hex: "38BDF8"), Color(hex: "2563EB")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .shadow(color: isCountdownActive ? Color.clear : Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .disabled(isCountdownActive)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 440)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    // MARK: - Cosmic Liquid Glass Backdrop (Inherited from MainView)
    private var cosmicLiquidGlassBackdrop: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(hex: "38BDF8").opacity(colorScheme == .dark ? 0.07 : 0.03),
                    Color(hex: "818CF8").opacity(colorScheme == .dark ? 0.04 : 0.02),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Unlocked Vault Content
    private var unlockedVaultContent: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                // Filter Tabs Segmented Switcher
                HStack(spacing: 2) {
                    ForEach(VaultFilterType.allCases) { filter in
                        let isSelected = viewModel.filterType == filter
                        let count: Int = {
                            switch filter {
                            case .all: return viewModel.items.count
                            case .folders: return viewModel.folderItems.count
                            case .files: return viewModel.fileItems.count
                            }
                        }()
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                viewModel.filterType = filter
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 10))
                                Text("\(filter.title) (\(count))")
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.secondary.opacity(0.14) : Color.clear)
                            )
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                    }
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.06)))
                .padding(.leading, 4)

                Spacer(minLength: 16)

                // Fast Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField(l10n("搜索隐匿项目...", "Search concealed items..."), text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                .frame(width: 140)

                Spacer(minLength: 8) // Appropriate spacing

                // User Notice Guide Button
                Button(action: {
                    viewModel.openUserNotice()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "info.circle.fill")
                        Text(l10n("使用须知", "User Notice"))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "38BDF8"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: "38BDF8").opacity(0.10)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)

                // Change Password Button
                Button(action: {
                    viewModel.changePasswordErrorMessage = nil
                    viewModel.isChangingPassword = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "key.fill")
                        Text(l10n("密码修改", "Change Password"))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.secondary.opacity(0.08)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)

                // Recovery Key View Button
                Button(action: {
                    isShowingRecoveryKey = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        Text(l10n("恢复密钥", "Recovery Key"))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "10B981"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: "10B981").opacity(0.10)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)

                // Recover Hidden Items Button
                Button(action: {
                    viewModel.rescueScanForHiddenItems()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkle.magnifyingglass")
                        Text(l10n("找回项目", "Recover"))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "38BDF8"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: "38BDF8").opacity(0.10)))
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)

                // Add Items Button
                Button(action: { selectFilesFromDialog() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(l10n("添加项目", "Add"))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "0284C7")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().opacity(0.2)

            ScrollView {
                VStack(spacing: 12) {
                    // Floating Liquid Glass Drop Zone
                    dropZoneHero

                    // Compact Master Checkbox Row
                    HStack(spacing: 8) {
                        let hasItems = !viewModel.displayedItems.isEmpty
                        let isAllSelected = hasItems && viewModel.selectedItemIds.count == viewModel.displayedItems.count
                        let isPartiallySelected = hasItems && !viewModel.selectedItemIds.isEmpty && !isAllSelected

                        Button(action: {
                            guard hasItems else { return }
                            if isAllSelected {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isAllSelected ? "checkmark.square.fill" : (isPartiallySelected ? "minus.square.fill" : "square"))
                                    .foregroundColor(hasItems && (isAllSelected || isPartiallySelected) ? Color(hex: "38BDF8") : .secondary.opacity(hasItems ? 0.8 : 0.4))
                                    .font(.system(size: 13))
                                Text(!hasItems || viewModel.selectedItemIds.isEmpty ? l10n("全选当前视图下所有项", "Select All in View") : l10n("已勾选 \(viewModel.selectedItemIds.count) 项，可批量解锁/锁定", "Selected \(viewModel.selectedItemIds.count) items for batch actions"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(hasItems && !viewModel.selectedItemIds.isEmpty ? Color(hex: "38BDF8") : .secondary.opacity(hasItems ? 1.0 : 0.5))
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasItems)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)

                    // Vault Items List
                    if viewModel.items.isEmpty {
                        emptyVaultPlaceholder
                    } else if viewModel.filterType == .all {
                        // Side-by-Side Dual Column Layout
                        HStack(alignment: .top, spacing: 16) {
                            // Section 1: Folders (Left Column)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color(hex: "F59E0B"))
                                        .font(.system(size: 12))
                                    Text(l10n("隐匿文件夹", "Folders"))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("(\(viewModel.displayedFolderItems.count))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if !viewModel.displayedFolderItems.isEmpty {
                                        Button(action: { viewModel.selectAllFolders() }) {
                                            Text(l10n("全选", "Select All")).font(.system(size: 10)).foregroundColor(Color(hex: "38BDF8"))
                                        }.buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 6).padding(.top, 4)

                                if viewModel.displayedFolderItems.isEmpty {
                                    Text(l10n("暂无文件夹", "No Folders")).font(.system(size: 12)).foregroundColor(.secondary).padding(.vertical, 20).frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 6) {
                                        ForEach(viewModel.displayedFolderItems) { item in
                                            vaultItemRow(item)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.04)))

                            // Section 2: Individual Files (Right Column)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(Color(hex: "38BDF8"))
                                        .font(.system(size: 12))
                                    Text(l10n("隐匿文件", "Files"))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("(\(viewModel.displayedFileItems.count))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if !viewModel.displayedFileItems.isEmpty {
                                        Button(action: { viewModel.selectAllFiles() }) {
                                            Text(l10n("全选", "Select All")).font(.system(size: 10)).foregroundColor(Color(hex: "38BDF8"))
                                        }.buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 6).padding(.top, 4)

                                if viewModel.displayedFileItems.isEmpty {
                                    Text(l10n("暂无单体文件", "No Files")).font(.system(size: 12)).foregroundColor(.secondary).padding(.vertical, 20).frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 6) {
                                        ForEach(viewModel.displayedFileItems) { item in
                                            vaultItemRow(item)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.04)))
                        }
                    } else if viewModel.filterType == .folders {
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.displayedFolderItems) { item in
                                vaultItemRow(item)
                            }
                        }
                    } else if viewModel.filterType == .files {
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.displayedFileItems) { item in
                                vaultItemRow(item)
                            }
                        }
                    }
                }
                .padding(20)
            }

            // Fixed Lower Area: Dynamic Dock (Normal vs Batch Selected)
            if viewModel.selectedItemIds.isEmpty || viewModel.items.isEmpty {
                // Default Dock: Centered Shield Lock Button + Footer Note
                VStack(spacing: 6) {
                    Button(action: { viewModel.lockVault() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14))
                            Text(l10n("立即锁定空间", "Lock Private Space Now"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "F43F5E").opacity(0.4), radius: 6, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()

                    // Security Footer Note
                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(Color(hex: "38BDF8"))
                            .font(.system(size: 10))
                        Text(l10n("本地处理 · 锁定后在访达与系统视图中隐藏", "Local processing · Hidden in Finder and system views when locked"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.secondary.opacity(0.12)),
                    alignment: .top
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Batch Action Toolbar Dock
                let targetCount = viewModel.items.filter { viewModel.selectedItemIds.contains($0.id) }.count
                HStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "38BDF8"))
                            .font(.system(size: 14))
                        Text(l10n("已选中 \(targetCount) 项", "Selected \(targetCount) items"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)

                        Button(l10n("取消选择", "Deselect")) {
                            viewModel.deselectAll()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    }

                    Spacer()

                    // Action 1: Batch Silent Unlock
                    let lockedCount = viewModel.items.filter { viewModel.selectedItemIds.contains($0.id) && ($0.status == .hidden || $0.status == .locked) }.count
                    if lockedCount > 0 {
                        Button(action: {
                            viewModel.batchUnlockSelected(silent: true)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.open.fill")
                                Text(l10n("批量解锁 (\(lockedCount))", "Batch Unlock (\(lockedCount))"))
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "10B981"), Color(hex: "059669")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                    }

                    // Action 2: Batch Lock
                    let unlockedCount = viewModel.items.filter { viewModel.selectedItemIds.contains($0.id) && $0.status != .hidden && $0.status != .locked }.count
                    if unlockedCount > 0 {
                        Button(action: {
                            viewModel.batchLockSelected()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                Text(l10n("批量上锁 (\(unlockedCount))", "Batch Lock (\(unlockedCount))"))
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PureButtonStyle())
                        .focusable(false)
                    }

                    // Action 3: Batch Remove Protection
                    Button(action: {
                        if targetCount == 0 {
                            viewModel.showToast(l10n("未选中任何需要解除保护的文件", "No items selected to remove protection"))
                        } else {
                            viewModel.isConfirmingBatchRemove = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.slash")
                            Text(l10n("批量解除保护", "Remove Protection"))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(targetCount == 0 ? Color.secondary.opacity(0.4) : Color(hex: "F59E0B"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(targetCount == 0 ? Color.secondary.opacity(0.06) : Color(hex: "F59E0B").opacity(0.12)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .disabled(targetCount == 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.secondary.opacity(0.15)),
                    alignment: .top
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Empty Vault Placeholder
    private var emptyVaultPlaceholder: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "38BDF8").opacity(0.12))
                    .frame(width: 64, height: 64)
                    .blur(radius: 8)

                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "38BDF8"))
            }

            VStack(spacing: 4) {
                Text(l10n("空间当前为空", "Private Space is Empty"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            Button(action: {
                viewModel.rescueScanForHiddenItems()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text(l10n("扫描本地隐藏项目", "Scan Hidden Items"))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "38BDF8"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "38BDF8").opacity(0.12)))
            }
            .buttonStyle(PureButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Vault Item Row
    private func vaultItemRow(_ item: VaultItem) -> some View {
        let isSelected = viewModel.selectedItemIds.contains(item.id)
        return HStack(spacing: 10) {
            // Checkbox
            Button(action: {
                viewModel.toggleItemSelection(id: item.id)
            }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? Color(hex: "38BDF8") : .secondary.opacity(0.6))
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)

            // Icon Pod
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.status == .hidden
                                ? [Color(hex: "10B981"), Color(hex: "059669")]
                                : [Color(hex: "38BDF8"), Color(hex: "0284C7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: (item.status == .hidden ? Color(hex: "10B981") : Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: (item.path as NSString).pathExtension.isEmpty ? "folder.fill" : "doc.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 13))
            }

            // Name & Size
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(item.formattedSize)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 110, alignment: .leading)

            // Path (Omitted in dual-column to save horizontal space, name is enough)

            Spacer()

            // Status Badge
            Circle()
                .fill(item.status == .hidden ? Color(hex: "10B981") : Color(hex: "38BDF8"))
                .frame(width: 6, height: 6)
                .help(item.status == .hidden ? l10n("已锁定", "Locked") : l10n("已解锁", "Unlocked"))

            // 3 Actions: Unlock / Lock / Finder / Remove Protection
            HStack(spacing: 6) {
                if item.status == .hidden {
                    Button(action: {
                        viewModel.unlockAndOpenInFinder(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.open.fill")
                            Text(l10n("解锁", "Unlock"))
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "10B981"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "10B981").opacity(0.12)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)

                    Button(action: {
                        viewModel.removeProtection(item: item)
                    }) {
                        Text(l10n("解除保护", "Remove"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                } else {
                    Button(action: {
                        viewModel.lockItem(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                            Text(l10n("上锁", "Lock"))
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F43F5E"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "F43F5E").opacity(0.12)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)

                    Button(action: {
                        viewModel.openAndHighlightInFinder(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "folder")
                            Text(l10n("访达", "Finder"))
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.10)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)

                    Button(action: {
                        viewModel.removeProtection(item: item)
                    }) {
                        Text(l10n("解除保护", "Remove"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                }
            }
            .frame(width: 180, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color(hex: "38BDF8").opacity(0.08) : Color.secondary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(hex: "38BDF8").opacity(0.35) : Color.secondary.opacity(0.08), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Drop Zone Hero
    private var dropZoneHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isTargeted ? Color(hex: "38BDF8") : Color.secondary.opacity(0.20),
                    style: StrokeStyle(lineWidth: isTargeted ? 1.8 : 1.2, dash: isTargeted ? [8, 4] : [6, 4])
                )
                .frame(height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isTargeted ? Color(hex: "38BDF8").opacity(0.10) : Color.secondary.opacity(0.03))
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isTargeted ? [Color(hex: "06B6D4"), Color(hex: "3B82F6")] : [Color(hex: "38BDF8"), Color(hex: "6366F1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(hex: "38BDF8").opacity(isTargeted ? 0.45 : 0.25), radius: isTargeted ? 8 : 4, x: 0, y: 2)

                    Image(systemName: isTargeted ? "arrow.down.doc.fill" : "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                Text(isTargeted ? l10n("松开加入隐藏", "Drop to Hide") : l10n("拖入文件夹或文件到此处", "Drop folders or files here"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isTargeted ? Color(hex: "38BDF8") : .primary)
            }
            .padding(.horizontal, 18)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            let box = DroppedURLBox()
            let group = DispatchGroup()
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url { box.append(url) }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let urls = box.retrieve()
                if !urls.isEmpty {
                    viewModel.addFiles(urls: urls, type: .hidden)
                }
            }
            return true
        }
    }

    // MARK: - Holographic Lock Shield Hero (Clean · Enlarged · Minimalist)
    private var luminousVaultSphereHero: some View {
        ZStack {
            // Ambient Aura Glow (Soft glow with no rigid circle border)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "38BDF8").opacity(0.25),
                            Color(hex: "818CF8").opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 105
                    )
                )
                .frame(width: 210, height: 210)
                .blur(radius: 28)

            // Enlarged Shield Lock Icon (vibrant cyan-indigo gradient)
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 106, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "38BDF8"), Color(hex: "818CF8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "38BDF8").opacity(0.40), radius: 16, x: 0, y: 5)
        }
        .frame(height: 140)
        .padding(.bottom, 8)
    }

    // MARK: - First Time Setup Content
    private var firstTimeSetupContent: some View {
        VStack(spacing: 16) {
            Spacer()

            // Holographic Lock Shield
            luminousVaultSphereHero

            VStack(spacing: 6) {
                Text(l10n("设置主密码", "Set Master Password"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(l10n("用于解锁已隐藏的文件，请妥善保管", "Used to unlock hidden files. Please keep it safe."))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Glass Setup Card
            VStack(spacing: 12) {
                SecureField(l10n("主密码 (至少 6 位)", "Password (6+ chars)"), text: $newPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                    .frame(width: 280)

                SecureField(l10n("确认密码", "Confirm password"), text: $confirmPasswordInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                    .frame(width: 280)

                TextField(l10n("密码提示 (选填)", "Password hint (optional)"), text: $passwordHintInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                    .frame(width: 280)

                Button(action: {
                    if newPasswordInput == confirmPasswordInput && newPasswordInput.count >= 6 {
                        viewModel.setupMasterPassword(password: newPasswordInput, hint: passwordHintInput)
                    }
                }) {
                    Text(l10n("完成设置", "Done"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 38)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6366F1"), Color(hex: "3B82F6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 8, x: 0, y: 3)
                        )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()
                .disabled(newPasswordInput.count < 6 || newPasswordInput != confirmPasswordInput)
                .opacity(newPasswordInput.count >= 6 && newPasswordInput == confirmPasswordInput ? 1.0 : 0.5)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 0.8)
                    )
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Locked Gate Content
    private var lockedGateContent: some View {
        VStack(spacing: 14) {
            Spacer()

            // Holographic Lock Shield Hero
            luminousVaultSphereHero

            VStack(spacing: 5) {
                Text(l10n("独立空间", "Private Space"))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(l10n("验证 Touch ID 或输入主密码以解锁", "Verify Touch ID or enter master password to unlock"))
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 6)

            // Glass Unlock Card
            VStack(spacing: 14) {
                // Official Apple-Style Touch ID Button (Neutral Monochrome)
                Button(action: { viewModel.unlockVaultWithBiometrics() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "touchid")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(MacAegisTheme.primaryText(for: colorScheme))
                        Text(l10n("使用 Touch ID 解锁", "Unlock with Touch ID"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MacAegisTheme.primaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.10), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .help(l10n("使用 Touch ID 触控 ID 解锁", "Unlock with Touch ID"))

                // Subtle Divider
                HStack(spacing: 10) {
                    Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 0.5)
                    Text(l10n("或输入主密码", "or enter master password"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                    Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 0.5)
                }
                .padding(.vertical, 2)

                // Password Input Bar
                HStack(spacing: 8) {
                    Image(systemName: viewModel.lockoutCountdown > 0 ? "lock.slash.fill" : "key.fill")
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.lockoutCountdown > 0 ? Color(hex: "F59E0B") : (viewModel.isPasswordError ? Color(hex: "EF4444") : Color(hex: "38BDF8")))
                        .padding(.leading, 12)

                    ZStack(alignment: .leading) {
                        if viewModel.lockoutCountdown > 0 {
                            Text(l10n("尝试过多，请 \(viewModel.lockoutCountdown) 秒后重试", "Too many attempts. Try again in \(viewModel.lockoutCountdown)s"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                        } else if let errorMsg = viewModel.passwordErrorMessage {
                            Text(errorMsg)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "EF4444"))
                        } else {
                            SecureField(l10n("输入主密码", "Enter Master Password"), text: $viewModel.passwordInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .onSubmit {
                                    viewModel.unlockWithPassword()
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: { viewModel.unlockWithPassword() }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .padding(.trailing, 8)
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .disabled(viewModel.lockoutCountdown > 0 || viewModel.passwordInput.isEmpty)
                    .opacity(viewModel.lockoutCountdown > 0 || viewModel.passwordInput.isEmpty ? 0.3 : 1.0)
                }
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(viewModel.lockoutCountdown > 0 ? Color(hex: "F59E0B").opacity(0.12) : (viewModel.isPasswordError ? Color(hex: "EF4444").opacity(0.12) : Color.secondary.opacity(0.06)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(viewModel.lockoutCountdown > 0 ? Color(hex: "F59E0B").opacity(0.5) : (viewModel.isPasswordError ? Color(hex: "EF4444").opacity(0.5) : Color.white.opacity(0.08)), lineWidth: 0.8)
                )
                .modifier(VaultShakeEffect(animatableData: CGFloat(viewModel.shakeAttempts)))
                .animation(.default, value: viewModel.shakeAttempts)

                // Password Hint (Cleanly separated)
                if let hint = viewModel.passwordHint, !hint.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(l10n("密码提示: \(hint)", "Password hint: \(hint)"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                // Forgot Password / Recovery Key Link (Cleanly separated)
                Button(action: {
                    viewModel.recoveryErrorMessage = nil
                    viewModel.recoveryCodeInput = ""
                    viewModel.recoveryNewPasswordInput = ""
                    viewModel.recoveryConfirmPasswordInput = ""
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isRecoveringWithCode = true
                    }
                }) {
                    Text(l10n("忘记密码？使用 64 位恢复密钥重置", "Forgot password? Reset with 64-character recovery key"))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "38BDF8").opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .frame(width: 320)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 0.8)
                    )
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectFilesFromDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = l10n("隐藏", "Hide")
        if panel.runModal() == .OK {
            viewModel.addFiles(urls: panel.urls, type: .hidden)
        }
    }
}

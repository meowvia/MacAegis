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

                Text(l10n("确认批量解除保护？", "Confirm Batch Remove Protection?"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
            }

            Text(l10n("即将解除选中的 \(viewModel.selectedItemIds.count) 个项目的隐匿保护。解除后文件将从隐匿列表移出并在访达中恢复正常可见，文件内容 100% 完好无损。", "Selected \(viewModel.selectedItemIds.count) items will be unhidden and removed from privacy protection. Files remain 100% intact."))
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
                    Text(l10n("修改保险箱主密码", "Change Master Password"))
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
                    Text(l10n("使用灾难恢复码找回", "Recover with Disaster Key"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
            }

            Divider().opacity(0.2)

            Text(l10n("输入 64 位恢复码可直接重置主密码并无损解锁所有文件", "Enter your 64-character recovery key to reset master password and unlock."))
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
                TextField(l10n("AEGIS-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX", "Recovery Key"), text: $viewModel.recoveryCodeInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
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

            Text(l10n("这是您保险箱的专属恢复密钥。请将其抄写并存放在安全的离线地点。一旦遗忘主密码，可用此密钥 100% 找回所有已锁文件。", "This is your vault recovery key. Please keep it in a safe offline location. If you forget your master password, use this key to restore all files."))
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

    // MARK: - Cosmic Liquid Glass Backdrop
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

                // Iridescent Magenta / Violet Glow
                RadialGradient(
                    colors: [Color(hex: "C084FC").opacity(0.16), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 550
                )
                .ignoresSafeArea()

                // Electric Cyan Caustics Bloom
                RadialGradient(
                    colors: [Color(hex: "38BDF8").opacity(0.14), Color.clear],
                    center: .bottomTrailing,
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
                    colors: [Color(hex: "38BDF8").opacity(0.18), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Unlocked Vault Content
    private var unlockedVaultContent: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(l10n("隐私隐匿", "Privacy Conceal"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "38BDF8"))
                    }
                    Text(l10n("文件原位瞬时锁定与隐匿，在访达中完全隐形且禁止预览。", "In-place instant concealment: fully invisible in Finder and preview-disabled."))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

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

                Spacer()

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

                // Change Password Button
                Button(action: {
                    viewModel.changePasswordErrorMessage = nil
                    viewModel.isChangingPassword = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "key.fill")
                        Text(l10n("密码", "Password"))
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
                        Text(l10n("恢复码", "Key"))
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

                    // Table Header Row with Master Checkbox
                    HStack(spacing: 8) {
                        Button(action: {
                            if viewModel.selectedItemIds.count == viewModel.displayedItems.count && !viewModel.displayedItems.isEmpty {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }) {
                            HStack(spacing: 6) {
                                let isAllSelected = !viewModel.displayedItems.isEmpty && viewModel.selectedItemIds.count == viewModel.displayedItems.count
                                Image(systemName: isAllSelected ? "checkmark.square.fill" : (viewModel.selectedItemIds.isEmpty ? "square" : "minus.square.fill"))
                                    .foregroundColor(isAllSelected || !viewModel.selectedItemIds.isEmpty ? Color(hex: "38BDF8") : .secondary)
                                    .font(.system(size: 13))
                                Text(viewModel.selectedItemIds.isEmpty ? l10n("全选", "Select All") : l10n("已选 \(viewModel.selectedItemIds.count) 项", "Selected \(viewModel.selectedItemIds.count)"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(viewModel.selectedItemIds.isEmpty ? .secondary : Color(hex: "38BDF8"))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 140, alignment: .leading)

                        Text(l10n("项目名称", "Item Name"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 150, alignment: .leading)

                        Text(l10n("原始路径", "Original Path"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(l10n("状态", "Status"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .center)

                        Text(l10n("操作", "Actions"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 180, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)

                    // Vault Items List
                    if viewModel.items.isEmpty {
                        emptyVaultPlaceholder
                    } else if viewModel.filterType == .all {
                        // Section 1: Folders
                        if !viewModel.displayedFolderItems.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color(hex: "F59E0B"))
                                        .font(.system(size: 12))
                                    Text(l10n("已隐匿文件夹", "Concealed Folders"))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("(\(viewModel.displayedFolderItems.count))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: {
                                        viewModel.selectAllFolders()
                                    }) {
                                        Text(l10n("全选文件夹", "Select All Folders"))
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "38BDF8"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 6)
                                .padding(.top, 4)

                                LazyVStack(spacing: 6) {
                                    ForEach(viewModel.displayedFolderItems) { item in
                                        vaultItemRow(item)
                                    }
                                }
                            }
                        }

                        // Section 2: Individual Files
                        if !viewModel.displayedFileItems.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(Color(hex: "38BDF8"))
                                        .font(.system(size: 12))
                                    Text(l10n("已隐匿单体文件", "Concealed Files"))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("(\(viewModel.displayedFileItems.count))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: {
                                        viewModel.selectAllFiles()
                                    }) {
                                        Text(l10n("全选文件", "Select All Files"))
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "38BDF8"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 6)
                                .padding(.top, 8)

                                LazyVStack(spacing: 6) {
                                    ForEach(viewModel.displayedFileItems) { item in
                                        vaultItemRow(item)
                                    }
                                }
                            }
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
            if viewModel.selectedItemIds.isEmpty {
                // Default Dock: Centered Shield Lock Button + Footer Note
                VStack(spacing: 6) {
                    Button(action: { viewModel.lockVault() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14))
                            Text(l10n("立即锁定隐匿", "Lock Privacy Vault Now"))
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
                        Text(l10n("本地私密安全隐匿保护 · 零云端上传 · 文件锁定后在访达与系统视图中原位隐匿且防预览", "On-device privacy protection · Zero cloud sync · Completely hidden in Finder when locked"))
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
                HStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "38BDF8"))
                            .font(.system(size: 14))
                        Text(l10n("已选中 \(viewModel.selectedItemIds.count) 项", "Selected \(viewModel.selectedItemIds.count) items"))
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
                        viewModel.isConfirmingBatchRemove = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.slash")
                            Text(l10n("批量解除保护", "Remove Protection"))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "F59E0B").opacity(0.12)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
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
                Text(l10n("隐匿库当前为空", "Privacy Conceal is Empty"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text(l10n("拖拽私人文件夹或敏感文件至上方区域，即可原位瞬时锁定并隐匿", "Drag private folders or sensitive files above to auto-lock and conceal"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Button(action: {
                viewModel.rescueScanForHiddenItems()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text(l10n("一键扫描并找回本地隐藏文件", "Scan & Recover Hidden Items"))
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
            .frame(width: 140, alignment: .leading)

            // Path
            Text(item.path)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Status Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(item.status == .hidden ? Color(hex: "10B981") : Color(hex: "38BDF8"))
                    .frame(width: 5, height: 5)
                Text(item.status == .hidden ? l10n("已锁定", "Locked") : l10n("已解锁", "Unlocked"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(item.status == .hidden ? Color(hex: "10B981") : Color(hex: "38BDF8"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill((item.status == .hidden ? Color(hex: "10B981") : Color(hex: "38BDF8")).opacity(0.12))
            )
            .frame(width: 80, alignment: .center)

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
                    style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])
                )
                .frame(height: 78)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isTargeted ? Color(hex: "38BDF8").opacity(0.08) : Color.secondary.opacity(0.03))
                )

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8"), Color(hex: "6366F1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Color(hex: "38BDF8").opacity(0.35), radius: 6, x: 0, y: 2)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n("拖入文件或文件夹到此处", "Drop files or folders here"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(l10n("将在访达中隐形并禁止空格键预览", "Hidden from Finder and QuickLook previews"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(l10n("松开添加", "Drop to add"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "38BDF8"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "38BDF8").opacity(0.12)))
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

    // MARK: - 3D Luminous Vault Sphere (GPU Hardware Composited · Zero CPU Overhead)
    private var luminousVaultSphereHero: some View {
        ZStack {
            // Layer 1: Ambient Outer Aura Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "38BDF8").opacity(0.25),
                            Color(hex: "818CF8").opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 190, height: 190)
                .blur(radius: 14)

            // Layer 2: Glass Sphere Core Body
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 150, height: 150)
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)

            // Layer 3: 3D Iridescent Rim Border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color(hex: "38BDF8").opacity(0.60),
                            Color(hex: "818CF8").opacity(0.40),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
                .frame(width: 150, height: 150)

            // Layer 4: Top-Left Specular Shine
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.80), Color.white.opacity(0.10), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 18)
                .rotationEffect(.degrees(-35))
                .offset(x: -36, y: -36)

            // Center Holographic Lock Shield Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 42))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "38BDF8"), Color(hex: "818CF8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "38BDF8").opacity(0.55), radius: 10, x: 0, y: 2)
        }
        .frame(width: 190, height: 190)
    }

    // MARK: - First Time Setup Content
    private var firstTimeSetupContent: some View {
        VStack(spacing: 20) {
            Spacer()

            // 3D Luminous Vault Sphere
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
        VStack(spacing: 20) {
            Spacer()

            // 3D Luminous Vault Sphere
            luminousVaultSphereHero

            VStack(spacing: 6) {
                Text(l10n("保险箱已锁定", "Vault is Locked"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(l10n("输入密码或使用 Touch ID 解锁", "Enter password or use Touch ID to unlock"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Glass Unlock Card
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if let errorMsg = viewModel.passwordErrorMessage {
                            Text(errorMsg)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "EF4444"))
                                .padding(.horizontal, 10)
                                .transition(.opacity)
                        } else {
                            SecureField(l10n("输入密码", "Enter password"), text: $viewModel.passwordInput)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .onSubmit {
                                    viewModel.unlockWithPassword()
                                }
                        }
                    }
                    .frame(width: 200, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isPasswordError ? Color(hex: "EF4444").opacity(0.12) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isPasswordError ? Color(hex: "EF4444") : Color.clear, lineWidth: 1.5)
                    )
                    .modifier(VaultShakeEffect(animatableData: CGFloat(viewModel.shakeAttempts)))
                    .animation(.default, value: viewModel.shakeAttempts)

                    Button(action: { viewModel.unlockWithPassword() }) {
                        Text(l10n("解锁", "Unlock"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "3B82F6"), Color(hex: "0284C7")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()

                    Button(action: { viewModel.unlockVaultWithBiometrics() }) {
                        Image(systemName: "touchid")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(9)
                            .background(
                                Circle()
                                    .fill(Color(hex: "10B981").opacity(0.15))
                            )
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                }

                if let hint = viewModel.passwordHint, !hint.isEmpty {
                    Text(l10n("密码提示: \(hint)", "Hint: \(hint)"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    viewModel.recoveryErrorMessage = nil
                    viewModel.recoveryCodeInput = ""
                    viewModel.recoveryNewPasswordInput = ""
                    viewModel.recoveryConfirmPasswordInput = ""
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isRecoveringWithCode = true
                    }
                }) {
                    Text(l10n("忘记密码？使用 64 位灾难恢复码找回", "Forgot password? Recover with disaster key"))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "38BDF8"))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(18)
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

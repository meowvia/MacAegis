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

            // Floating Toast Notification
            if let toast = viewModel.toastMessage {
                VStack {
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
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
            }
        }
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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(l10n("隐私保险箱", "Privacy Vault"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    Text(l10n("拖入文件或文件夹即可在访达中隐藏并禁止预览。", "Drag files or folders to hide them from Finder."))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Status Capsule Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 6, height: 6)
                    Text(l10n("\(viewModel.items.count) 个已隐藏项目", "\(viewModel.items.count) Hidden Items"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.08)))
                .padding(.leading, 6)

                Spacer()

                // Fast Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField(l10n("搜索已隐藏项目...", "Search hidden items..."), text: $viewModel.searchText)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                .frame(width: 170)

                // Add Items Button
                Button(action: { selectFilesFromDialog() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text(l10n("添加项目", "Add Items"))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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
                .focusEffectDisabled()
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().opacity(0.2)

            ScrollView {
                VStack(spacing: 14) {
                    // Floating Liquid Glass Drop Zone
                    dropZoneHero

                    // Table Header Row
                    HStack {
                        Text(l10n("项目名称", "Item Name"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 170, alignment: .leading)
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
                    } else {
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.displayedItems) { item in
                                vaultItemRow(item)
                            }
                        }
                    }
                }
                .padding(24)
            }

            // Fixed Lower Area: Centered Shield Lock Button + Footer Note
            VStack(spacing: 8) {
                Button(action: { viewModel.lockVault() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 15))
                        Text(l10n("立即上锁保险箱", "Lock Vault Now"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: "F43F5E").opacity(0.4), radius: 8, x: 0, y: 3)
                    )
                }
                .buttonStyle(PureButtonStyle())
                .focusable(false)
                .focusEffectDisabled()

                // Security Footer Note
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Color(hex: "38BDF8"))
                        .font(.system(size: 11))
                    Text(l10n("本地私密安全隐匿保护 · 零云端上传 · 文件上锁后在访达与系统视图中完全隐形", "On-device local privacy protection · Zero cloud sync · Completely hidden in Finder when locked"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.secondary.opacity(0.12)),
                alignment: .top
            )
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
                Text(l10n("保险箱当前为空", "Vault is Empty"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text(l10n("拖拽私人文件夹或敏感文件至上方区域，即可自动加密上锁并隐匿", "Drag private folders or sensitive files above to auto-encrypt and lock"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
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
        HStack(spacing: 12) {
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
                    .frame(width: 32, height: 32)
                    .shadow(color: (item.status == .hidden ? Color(hex: "10B981") : Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: (item.path as NSString).pathExtension.isEmpty ? "folder.fill" : "doc.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }

            // Name
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
                Text(item.status == .hidden ? l10n("已上锁", "Locked") : l10n("已解锁", "Unlocked"))
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

            // 3 Actions: Unlock (Opens Finder) / Lock / Open Finder (if unlocked) / Remove Protection
            HStack(spacing: 6) {
                if item.status == .hidden {
                    // LOCKED STATE: 1. Unlock (Reveals and opens Finder) 2. Remove Protection
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
                    .focusEffectDisabled()

                    Button(action: {
                        viewModel.removeProtection(item: item)
                    }) {
                        Text(l10n("解除保护", "Remove Protection"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                } else {
                    // UNLOCKED STATE: 1. Lock 2. Direct Finder 3. Remove Protection
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
                    .focusEffectDisabled()

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
                    .focusEffectDisabled()

                    Button(action: {
                        viewModel.removeProtection(item: item)
                    }) {
                        Text(l10n("解除保护", "Remove Protection"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(PureButtonStyle())
                    .focusable(false)
                    .focusEffectDisabled()
                }
            }
            .frame(width: 180, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.10), lineWidth: 0.8)
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

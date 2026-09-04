import SwiftUI
import AppKit
import MacAegisCore

@MainActor
public struct ScreenshotRenderer {
    public static func renderAll(outputDirectory: URL) {
        UserDefaults.standard.set("en", forKey: "appLanguage")

        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        print("Rendering 10 English screenshots to \(outputDirectory.path)...")

        // 01: Vault Setup Password
        render(
            name: "01_vault_setup_password_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .privacyVault) {
                MockVaultSetupPasswordView()
            }
        }

        // 02: Vault User Notice Countdown
        render(
            name: "02_vault_user_notice_countdown_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .privacyVault) {
                MockVaultNoticeView(countdown: 5)
            }
        }

        // 03: Vault User Notice Full
        render(
            name: "03_vault_user_notice_full_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .privacyVault) {
                MockVaultNoticeView(countdown: 0)
            }
        }

        // 04: Vault Concealed List with Toast
        render(
            name: "04_vault_concealed_list_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .privacyVault) {
                MockVaultListView(showToast: true)
            }
        }

        // 05: Vault Batch Operations Modal
        render(
            name: "05_vault_batch_operations_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .privacyVault) {
                MockVaultBatchView()
            }
        }

        // 06: Dashboard Clean
        render(
            name: "06_dashboard_clean_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .dashboard) {
                MockDashboardCleanView()
            }
        }

        // 07: Settings General
        render(
            name: "07_settings_general_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .dashboard) {
                MockSettingsView(scrollState: .top)
            }
        }

        // 08: Settings Security
        render(
            name: "08_settings_security_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .dashboard) {
                MockSettingsView(scrollState: .bottom)
            }
        }

        // 09: Uninstaller Progressive
        render(
            name: "09_uninstaller_progressive_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 880, height: 600)
        ) {
            MainFrameContainer(activeTab: .uninstaller) {
                MockUninstallerProgressiveView()
            }
        }

        // 10: MenuBar Telemetry
        render(
            name: "10_menubar_telemetry_en.png",
            outputDirectory: outputDirectory,
            size: CGSize(width: 340, height: 480)
        ) {
            MockMenuBarCardView()
        }

        print("All 10 English screenshots successfully rendered!")
    }

    private static func render<V: View>(
        name: String,
        outputDirectory: URL,
        size: CGSize,
        @ViewBuilder content: () -> V
    ) {
        let view = content()
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.colorScheme, .dark)
            .preferredColorScheme(.dark)

        let targetURL = outputDirectory.appendingPathComponent(name)

        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2.0 // 2x Retina Quality
        renderer.isOpaque = false

        if let cgImage = renderer.cgImage {
            let nsImage = NSImage(cgImage: cgImage, size: size)
            if let tiff = nsImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: targetURL)
                print("Generated: \(name)")
                return
            }
        }
        print("Failed to generate: \(name)")
    }
}

// MARK: - Reusable Mock Containers & Views

struct MainFrameContainer<Content: View>: View {
    let activeTab: NavigationTab
    let content: Content

    init(activeTab: NavigationTab, @ViewBuilder content: () -> Content) {
        self.activeTab = activeTab
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Window Header Bar with Traffic Lights
            HStack(spacing: 12) {
                // Traffic Lights
                HStack(spacing: 7) {
                    Circle().fill(Color(hex: "FF5F56")).frame(width: 12, height: 12)
                    Circle().fill(Color(hex: "FFBD2E")).frame(width: 12, height: 12)
                    Circle().fill(Color(hex: "27C93F")).frame(width: 12, height: 12)
                }
                .padding(.trailing, 6)

                // App Brand
                HStack(spacing: 6) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text("MacAegis")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Center Navigation Tabs
                HStack(spacing: 4) {
                    TabPillButton(title: "Smart Clean", icon: "bolt.shield.fill", isSelected: activeTab == .dashboard)
                    TabPillButton(title: "Uninstaller", icon: "trash", isSelected: activeTab == .uninstaller)
                    TabPillButton(title: "Privacy Conceal", icon: "lock.shield", isSelected: activeTab == .privacyVault)
                }
                .padding(3)
                .background(Capsule().fill(Color.secondary.opacity(0.12)))

                Spacer()

                // Right Telemetry & Settings
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "10B981")).frame(width: 6, height: 6)
                        Text("↓ 8K  ↑ 3K")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "10B981").opacity(0.10)))

                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color.secondary.opacity(0.10)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)

            Divider().opacity(0.2)

            // Content Stage
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 880, height: 600)
        .background(
            ZStack {
                Color(hex: "090A12").ignoresSafeArea()
                RadialGradient(
                    colors: [Color(hex: "C084FC").opacity(0.15), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 550
                )
                RadialGradient(
                    colors: [Color(hex: "38BDF8").opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 80,
                    endRadius: 500
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
        )
    }
}

struct TabPillButton: View {
    let title: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
        }
        .foregroundColor(isSelected ? .white : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isSelected ? Color(hex: "38BDF8").opacity(0.35) : Color.clear)
        )
    }
}

// MARK: - Specific View Mocks

struct MockVaultSetupPasswordView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8").opacity(0.3), Color(hex: "6366F1").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "38BDF8"))
            }

            VStack(spacing: 4) {
                Text("Set Master Password")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Used to unlock concealed files, please keep safely")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                RoundedTextFieldMock(placeholder: "Master Password (min 6 chars)")
                RoundedTextFieldMock(placeholder: "Confirm Password")
                RoundedTextFieldMock(placeholder: "Password Hint (Optional)")

                Button(action: {}) {
                    Text("Complete Setup")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "0284C7")], startPoint: .leading, endPoint: .trailing))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(width: 260)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))

            Spacer()
        }
    }
}

struct RoundedTextFieldMock: View {
    let placeholder: String
    var body: some View {
        HStack {
            Text(placeholder)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
    }
}

struct MockVaultNoticeView: View {
    let countdown: Int

    var body: some View {
        ZStack {
            MockVaultListView(showToast: false)
                .blur(radius: 4)

            Color.black.opacity(0.45)

            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "38BDF8"))
                        Text("Privacy Conceal · User Notice")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Welcome to MacAegis Privacy Conceal. Please take note of the following before use:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Safely Keep Master Password & Recovery Key")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("• Uses pure offline security without cloud upload.\n• A unique Recovery Key is generated; please back it up.\n• The recovery key is the sole credential to regain access if you forget your password.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("2. Avoid Setting Download Path to Locked Folders")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("• Locked folders pause external write/modification.\n• Avoid pointing download tools directly to locked folders to prevent write errors.\n• Download to standard folders first before concealing.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("3. Cloud Sync File Guidelines")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("• Cloud synced directories are isolated to prevent engine conflicts.\n• Copy files to local disk first before concealing.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("4. In-Place Protection & Performance")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("• Conceals files in-place without redundant copies or extra disk usage.\n• Stealth and recovery operations complete instantaneously.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 280)

                Button(action: {}) {
                    Text(countdown > 0 ? "I have read and understood (\(countdown)s)" : "I have read and understood")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "2563EB")], startPoint: .leading, endPoint: .trailing))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(width: 440)
            .background(Color(hex: "1E2030"))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }
}

struct MockVaultListView: View {
    let showToast: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Action Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Privacy Conceal")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color(hex: "38BDF8"))
                                .font(.system(size: 12))
                        }
                        Text("In-place lock & hide, vanished from Finder & QuickLook previews.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Filter Tabs
                    HStack(spacing: 4) {
                        FilterPillMock(title: "All (13)", isSelected: true)
                        FilterPillMock(title: "Folders (1)", isSelected: false)
                        FilterPillMock(title: "Files (12)", isSelected: false)
                    }
                    .padding(2)
                    .background(Capsule().fill(Color.secondary.opacity(0.08)))

                    HStack(spacing: 6) {
                        ActionBtnMock(title: "Notice", icon: "info.circle.fill", color: Color(hex: "38BDF8"))
                        ActionBtnMock(title: "Password", icon: "key.fill", color: .secondary)
                        ActionBtnMock(title: "Key", icon: "shield.lefthalf.filled.badge.checkmark", color: Color(hex: "10B981"))
                        ActionBtnMock(title: "Recover", icon: "sparkle.magnifyingglass", color: Color(hex: "38BDF8"))
                        ActionBtnMock(title: "Add", icon: "plus", color: .white, isPrimary: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Dropzone Hero
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.20), style: StrokeStyle(lineWidth: 1.2, dash: [6, 4]))
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.03)))

                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "6366F1")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 28, height: 28)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }

                        Text("Drop folders or files here")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)

                // Item List Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "square")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Select All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, alignment: .leading)

                    Text("Item Name")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 180, alignment: .leading)

                    Text("Original Path")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Status")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .center)

                    Text("Actions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 110, alignment: .trailing)
                }
                .padding(.horizontal, 20)

                // List Items
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        // Section Header
                        HStack {
                            Image(systemName: "folder.fill").foregroundColor(.orange).font(.system(size: 10))
                            Text("Concealed Folders (1)").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                            Spacer()
                            Text("Select All Folders").font(.system(size: 9)).foregroundColor(Color(hex: "38BDF8"))
                        }
                        .padding(.horizontal, 20)

                        VaultRowMock(name: "MacAegis-Test", size: "46.29 GB", path: "/Volumes/2T/MacAegis-Test", isFolder: true, isLocked: true)

                        HStack {
                            Image(systemName: "doc.fill").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 10))
                            Text("Concealed Files (12)").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                            Spacer()
                            Text("Select All Files").font(.system(size: 9)).foregroundColor(Color(hex: "38BDF8"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        VaultRowMock(name: "3d_honeycomb_pattern_wallpaper.jpg", size: "610 KB", path: "/Volumes/2T/Wallpapers/3d_honeycomb_pattern.jpg", isFolder: false, isLocked: true)
                        VaultRowMock(name: "00581a2b-2eb3-40f1-bb26.png", size: "2 MB", path: "/Volumes/2T/Wallpapers/00581a2b-2eb3-40f1.png", isFolder: false, isLocked: true)
                        VaultRowMock(name: "2025_ana_de_armas_eve_ballerina.jpg", size: "1 MB", path: "/Volumes/2T/Wallpapers/2025_ana_de_armas.jpg", isFolder: false, isLocked: true)
                        VaultRowMock(name: "Screenshot 2025-08-14 14.15.36.png", size: "7.7 MB", path: "/Volumes/2T/Wallpapers/Screenshot 14.15.36.png", isFolder: false, isLocked: true)
                        VaultRowMock(name: "Screenshot 2025-08-14 14.15.56.png", size: "7.8 MB", path: "/Volumes/2T/Wallpapers/Screenshot 14.15.56.png", isFolder: false, isLocked: true)
                    }
                }

                // Bottom Bar
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield").font(.system(size: 9)).foregroundColor(Color(hex: "38BDF8"))
                        Text("100% Local Offline Encryption · Zero Cloud Telemetry").font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text("Lock Vault Immediately")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "DC2626")], startPoint: .leading, endPoint: .trailing)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981")).font(.system(size: 12))
                        Text("Concealed 12 items into Vault").font(.system(size: 11, weight: .bold)).foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "1E2030")).overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)))
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

struct VaultRowMock: View {
    let name: String
    let size: String
    let path: String
    let isFolder: Bool
    let isLocked: Bool

    var body: some View {
        HStack {
            Image(systemName: "square")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: isFolder ? "folder.fill" : "doc.fill")
                    .foregroundColor(isFolder ? .orange : Color(hex: "38BDF8"))
                    .font(.system(size: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(size)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 220, alignment: .leading)

            Text(path)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)

            Spacer()

            HStack(spacing: 4) {
                Circle().fill(Color(hex: "10B981")).frame(width: 5, height: 5)
                Text("Locked")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(hex: "10B981"))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color(hex: "10B981").opacity(0.10)))
            .frame(width: 70, alignment: .center)

            HStack(spacing: 4) {
                Text("Unlock")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "10B981"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "10B981").opacity(0.10)))

                Text("Remove")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.08)))
            }
            .frame(width: 110, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.03)))
        .padding(.horizontal, 16)
    }
}

struct FilterPillMock: View {
    let title: String
    let isSelected: Bool
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(isSelected ? Color(hex: "38BDF8").opacity(0.3) : Color.clear))
    }
}

struct ActionBtnMock: View {
    let title: String
    let icon: String
    let color: Color
    var isPrimary: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isPrimary ? Color(hex: "38BDF8") : Color.secondary.opacity(0.08))
        )
    }
}

struct MockVaultBatchView: View {
    var body: some View {
        ZStack {
            MockVaultListView(showToast: false)
                .blur(radius: 3)

            Color.black.opacity(0.45)

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "F59E0B"))
                        .font(.system(size: 16))
                    Text("Confirm Batch Remove Protection?")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }

                Text("Selected 13 items will be unhidden and removed from privacy protection. Files remain 100% intact.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("Cancel")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {}) {
                        Text("Remove Protection")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(hex: "F59E0B")))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(18)
            .frame(width: 360)
            .background(Color(hex: "1E2030"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }
}

struct MockDashboardCleanView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                Spacer()

                // Header
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Your Mac is Running Smoothly")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "10B981"))
                    }

                    Text("Pure Native Architecture · Smart Deep Clean · Privacy Shield")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "10B981")).frame(width: 5, height: 5)
                        Text("Pure Native Swift · Local Offline")

                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "10B981").opacity(0.10)))
                    .padding(.top, 4)
                }

                // 3D Glass Bubble
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8").opacity(0.20), Color(hex: "6366F1").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(Circle().stroke(Color(hex: "38BDF8").opacity(0.3), lineWidth: 1))

                    VStack(spacing: 2) {
                        Text("0 KB")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Reclaimable Space")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)

                // 4 Pod Cards Grid
                HStack(spacing: 14) {
                    PodCardMock(icon: "shippingbox.fill", title: "System Cache & Logs", size: "0 KB", color: Color(hex: "38BDF8"))
                    PodCardMock(icon: "shield.fill", title: "Privacy Traces & Chat", size: "0 KB", color: Color(hex: "F59E0B"))
                    PodCardMock(icon: "folder.fill", title: "Big Files & Installers", size: "0 KB", color: Color(hex: "818CF8"))
                    PodCardMock(icon: "trash.fill", title: "Uninstalled Residuals", size: "0 KB", color: Color(hex: "10B981"))
                }
                .frame(width: 760)

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("View Deep System Scan Details")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "38BDF8"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "38BDF8").opacity(0.10)))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Top Right Bilingual Language Toast Bubble
            HStack(spacing: 6) {
                Image(systemName: "globe").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text("English / Chinese Bilingual").font(.system(size: 10, weight: .bold)).foregroundColor(.primary)
                    Text("Click gear icon to switch language").font(.system(size: 9)).foregroundColor(.secondary)
                }
                Image(systemName: "xmark").font(.system(size: 8)).foregroundColor(.secondary).padding(.leading, 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "1E2030")).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.8)))
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
    }
}

struct PodCardMock: View {
    let icon: String
    let title: String
    let size: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(size)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
        .frame(maxWidth: .infinity)
    }
}

enum SettingsScrollMock { case top, bottom }

struct MockSettingsView: View {
    let scrollState: SettingsScrollMock

    var body: some View {
        ZStack {
            MockDashboardCleanView()
                .blur(radius: 3)

            Color.black.opacity(0.45)

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red.opacity(0.85)).frame(width: 10, height: 10)
                        Image(systemName: "gearshape.fill").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 12))
                        Text("Preferences").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(hex: "17192B"))

                Divider().opacity(0.2)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if scrollState == .top {
                            SettingsSectionHeader(icon: "macwindow", title: "General & Appearance")
                            SettingsRowItem(title: "Appearance Mode", subtitle: "Follow System / Light / Dark", control: "Follow System")
                            SettingsRowItem(title: "Display Language", subtitle: "Switch interface language (Instant)", control: "English")

                            SettingsSectionHeader(icon: "gauge.with.needle", title: "Hardware Monitoring & Units")
                            SettingsRowItem(title: "Temperature Unit", subtitle: "System monitor and status bar unit", control: "Celsius (°C)")
                            SettingsRowToggle(title: "Menu Bar Real-Time Telemetry", subtitle: "Display network, temperature & CPU load on top bar", isOn: true)

                            SettingsSectionHeader(icon: "shield.lefthalf.filled", title: "Cleaning & System Protection")
                            SettingsRowItem(title: "Default Cleaning Method", subtitle: "Move to Trash can be restored anytime", control: "Move to Trash (Rec)")
                        } else {
                            SettingsSectionHeader(icon: "shield.lefthalf.filled", title: "Cleaning & System Protection")
                            SettingsRowToggle(title: "Trash Residual Monitor", subtitle: "Notify to clean leftovers when deleting apps in Finder", isOn: true)
                            SettingsRowToggle(title: "Launch at Login", subtitle: "Start MacAegis background helper at system login", isOn: false)
                            SettingsRowItem(title: "Close Window Behavior (Cmd+W)", subtitle: "Action when clicking red close button", control: "Keep Running")
                            SettingsRowStatus(title: "Full Disk Access (FDA)", subtitle: "Grant permission to scan logs & sandbox residuals", status: "Authorized")

                            SettingsSectionHeader(icon: "lock.shield", title: "Privacy Policy & Security Commitments")
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.shield.fill").foregroundColor(Color(hex: "10B981")).font(.system(size: 11))
                                    Text("100% Pure Local Offline Execution").font(.system(size: 10, weight: .bold)).foregroundColor(.primary)
                                }
                                Text("All disk scans, cleanups, and encryption run locally on your Mac. No analytics or cloud uploads.").font(.system(size: 9)).foregroundColor(.secondary)

                                HStack(spacing: 5) {
                                    Image(systemName: "key.fill").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 11))
                                    Text("Keychain & Hardware Derived Security").font(.system(size: 10, weight: .bold)).foregroundColor(.primary)
                                }
                                Text("Vault passwords and DEK keys are safeguarded in native macOS Keychain with PBKDF2.").font(.system(size: 9)).foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.04)))
                        }
                    }
                    .padding(16)
                }

                Divider().opacity(0.2)

                HStack {
                    Text("MacAegis v0.2.1 · Check for Updates")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {}) {
                        Text("Done")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color(hex: "3B82F6")))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(hex: "17192B"))
            }
            .frame(width: 440, height: 380)
            .background(Color(hex: "1A1C2C"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
    }
}

struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(Color(hex: "38BDF8"))
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }
}

struct SettingsRowItem: View {
    let title: String
    let subtitle: String
    let control: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
                Text(subtitle).font(.system(size: 9)).foregroundColor(.secondary)
            }
            Spacer()
            Text(control)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(hex: "3B82F6")))
        }
        .padding(.vertical, 3)
    }
}

struct SettingsRowToggle: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
                Text(subtitle).font(.system(size: 9)).foregroundColor(.secondary)
            }
            Spacer()
            Capsule()
                .fill(isOn ? Color(hex: "3B82F6") : Color.secondary.opacity(0.3))
                .frame(width: 32, height: 18)
                .overlay(
                    Circle().fill(.white).frame(width: 14, height: 14)
                        .offset(x: isOn ? 6 : -6)
                )
        }
        .padding(.vertical, 3)
    }
}

struct SettingsRowStatus: View {
    let title: String
    let subtitle: String
    let status: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
                Text(subtitle).font(.system(size: 9)).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 3) {
                Circle().fill(Color(hex: "10B981")).frame(width: 5, height: 5)
                Text(status).font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "10B981"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(hex: "10B981").opacity(0.12)))
        }
        .padding(.vertical, 3)
    }
}

struct MockUninstallerProgressiveView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Action Header
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "38BDF8")).frame(width: 6, height: 6)
                    Text("70 Apps Detected")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundColor(.secondary)
                    Text("Search applications...").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // App List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    // App 1: Cinetry
                    AppRowCollapsedMock(icon: "film.fill", name: "Cinetry", bundleId: "com.gstory.cinetry", size: "147.7 MB")

                    // App 2: Claude (Expanded)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chevron.down").font(.system(size: 9)).foregroundColor(.secondary)
                            Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text("Claude").font(.system(size: 11, weight: .bold)).foregroundColor(.primary)
                                    Text("Expanded").font(.system(size: 8)).foregroundColor(Color(hex: "38BDF8"))
                                }
                                Text("com.anthropic.claudefordesktop").font(.system(size: 8)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("11.5 GB").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(.primary)
                            Text("Uninstall")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color(hex: "38BDF8"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "38BDF8").opacity(0.12)))
                        }

                        // Sub-items
                        VStack(spacing: 4) {
                            SubItemRowMock(type: "Main App Bundle", path: "/Applications/Claude.app", size: "815.2 MB", color: Color(hex: "38BDF8"))
                            SubItemRowMock(type: "Application Support", path: "/Users/seoigor/Library/Application Support/Claude", size: "10.68 GB", color: .pink)
                            SubItemRowMock(type: "Runtime Cache", path: "/Users/seoigor/Library/Caches/com.anthropic.claudefordesktop", size: "283 KB", color: .orange)
                            SubItemRowMock(type: "Runtime Cache", path: "/Users/seoigor/Library/Caches/com.anthropic.claudefordesktop.ShipIt", size: "4 KB", color: .orange)
                            SubItemRowMock(type: "Preferences", path: "/Users/seoigor/Library/Preferences/com.anthropic.claudefordesktop.plist", size: "4 KB", color: .purple)
                            SubItemRowMock(type: "Runtime Cache", path: "/Users/seoigor/Library/HTTPStorages/com.anthropic.claudefordesktop", size: "1.1 MB", color: .orange)
                            SubItemRowMock(type: "Runtime Logs", path: "/Users/seoigor/Library/Logs/Claude", size: "553 KB", color: .gray)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.04)))

                        HStack {
                            Text("Contains 7 associated items · Total 11.5 GB").font(.system(size: 9)).foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                Text("Confirm Deep Uninstall")
                            }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "EF4444")))
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "38BDF8").opacity(0.2), lineWidth: 0.8)))

                    // App 3: Cloudflare WARP
                    AppRowCollapsedMock(icon: "shield.lefthalf.filled", name: "Cloudflare WARP", bundleId: "com.cloudflare.1dot1dot1dot1.macos", size: "361.3 MB")
                    AppRowCollapsedMock(icon: "doc.plaintext", name: "CotEditor", bundleId: "com.coteditor.CotEditor", size: "32.5 MB")
                    AppRowCollapsedMock(icon: "arrow.down.circle", name: "Downie 4", bundleId: "com.charliemonroe.Downie-4", size: "153.3 MB")
                    AppRowCollapsedMock(icon: "paintpalette", name: "Draw Things", bundleId: "com.liuliu.draw-things", size: "232 MB")
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct AppRowCollapsedMock: View {
    let icon: String
    let name: String
    let bundleId: String
    let size: String

    var body: some View {
        HStack {
            Image(systemName: "chevron.right").font(.system(size: 8)).foregroundColor(.secondary)
            Image(systemName: icon).foregroundColor(Color(hex: "38BDF8")).font(.system(size: 13))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
                Text(bundleId).font(.system(size: 8)).foregroundColor(.secondary)
            }
            Spacer()
            Text(size).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.secondary)
            Text("Uninstall")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(hex: "38BDF8"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "38BDF8").opacity(0.12)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.03)))
    }
}

struct SubItemRowMock: View {
    let type: String
    let path: String
    let size: String
    let color: Color

    var body: some View {
        HStack {
            Text(type)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
                .frame(width: 90, alignment: .leading)

            Text(path)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "magnifyingglass").font(.system(size: 7))
                Text("Reveal").font(.system(size: 8))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.08)))

            Text(size)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

struct MockMenuBarCardView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text("MacAegis")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "10B981")).frame(width: 5, height: 5)
                    Text("Direct Network")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color(hex: "10B981").opacity(0.12)))
            }

            // Net Speed Hero
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down").foregroundColor(Color(hex: "10B981")).font(.system(size: 11, weight: .bold))
                    Text("7 KB/s").font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(.primary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up").foregroundColor(Color(hex: "38BDF8")).font(.system(size: 11, weight: .bold))
                    Text("681 B/s").font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(.primary)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))

            // Metrics
            VStack(spacing: 10) {
                TelemetryProgressMock(title: "CPU Load", value: "9.4%", progress: 0.094, barColor: Color(hex: "38BDF8"))
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium").foregroundColor(.orange).font(.system(size: 10))
                        Text("SoC Core Temp").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("44°C · 0 RPM (Silent)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.primary)
                }

                TelemetryProgressMock(title: "Unified Memory", value: "11.17 GB / 17.18 GB", progress: 0.65, barColor: Color(hex: "A855F7"))

                // Disk 1
                DiskTelemetryRowMock(icon: "internaldrive", name: "Macintosh HD", free: "72.6 GB free / 245.1 GB", progress: 0.70, color: Color(hex: "38BDF8"))
                // Disk 2
                DiskTelemetryRowMock(icon: "externaldrive", name: "2T", free: "1.55 TB free / 2 TB", progress: 0.22, color: .orange)
                // Disk 3
                DiskTelemetryRowMock(icon: "externaldrive", name: "macOS backup", free: "40.38 GB free / 300 GB", progress: 0.86, color: .orange)
            }

            Divider().opacity(0.2)

            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                    Text("Quit MacAegis")
                    Spacer()
                    Text("⌘Q").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "EF4444"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "EF4444").opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 320)
        .background(Color(hex: "181A28"))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
    }
}

struct TelemetryProgressMock: View {
    let title: String
    let value: String
    let progress: Double
    let barColor: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(title).font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                Spacer()
                Text(value).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                    Capsule().fill(barColor).frame(width: geo.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct DiskTelemetryRowMock: View {
    let icon: String
    let name: String
    let free: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 9))
                    Text(name).font(.system(size: 10, weight: .medium)).foregroundColor(.primary)
                }
                Spacer()
                Text(free).font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

import SwiftUI
import MacAegisCore

public struct MenuBarCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onOpenMainWindow: () -> Void

    public init(viewModel: DashboardViewModel, onOpenMainWindow: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenMainWindow = onOpenMainWindow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Header: Logo + App Name + Proxy Mode Pill
            HStack(spacing: 8) {
                MacAegisLogoView(size: 20, isGlowing: true)
                Text("MacAegis")
                    .font(.system(size: 14, weight: .bold, design: .rounded))

                Spacer()

                // Proxy Pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: viewModel.networkSpeed.proxyMode.colorHex))
                        .frame(width: 6, height: 6)
                    Text(viewModel.networkSpeed.proxyMode.localizedTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: viewModel.networkSpeed.proxyMode.colorHex))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color(hex: viewModel.networkSpeed.proxyMode.colorHex).opacity(0.12)))
            }

            Divider().opacity(0.4)

            // 2. Real-time Network Speed
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "10B981"))
                    Text(viewModel.networkSpeed.formattedDownload)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "06B6D4"))
                    Text(viewModel.networkSpeed.formattedUpload)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))

            // 3. Telemetry Rows (CPU & SoC Temp, RAM, Disk Storage)
            VStack(spacing: 8) {
                // CPU Load & SoC Temperature
                VStack(spacing: 4) {
                    HStack {
                        Text(l10n("CPU 负载", "CPU Load"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", viewModel.systemMetrics.cpuUsagePercent))%")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    ProgressView(value: viewModel.systemMetrics.cpuUsagePercent / 100.0)
                        .tint(Color(hex: "06B6D4"))

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text(l10n("SoC 核心温度", "SoC Temp"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(viewModel.thermalAndFan.formattedTemperature) · \(viewModel.thermalAndFan.formattedFanSpeed)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                // RAM
                HStack {
                    Text(l10n("统一内存", "Memory"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.systemMetrics.formattedMemoryUsed) / \(viewModel.systemMetrics.formattedMemoryTotal)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                ProgressView(value: viewModel.systemMetrics.memoryUsagePercent / 100.0)
                    .tint(Color(hex: "A855F7"))

                // Disk Storage (Dynamic Multi-Disk Detection)
                ForEach(viewModel.mountedDrives) { drive in
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: drive.icon)
                                .font(.system(size: 10))
                                .foregroundColor(drive.isInternal ? Color(hex: "38BDF8") : Color(hex: "F59E0B"))
                            Text(drive.name)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text(l10n("余 \(drive.formattedFree) / 共 \(drive.formattedTotal)", "Free \(drive.formattedFree) / Total \(drive.formattedTotal)"))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        ProgressView(value: drive.usagePercent / 100.0)
                            .tint(drive.isInternal ? Color(hex: "38BDF8") : Color(hex: "F59E0B"))
                    }
                }
            }

            Divider().opacity(0.4)

            // 4. Quick Actions (Clean Quit)
            VStack(spacing: 6) {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "EF4444"))
                        Text(l10n("退出 MacAegis", "Quit MacAegis"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("⌘Q")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.secondary.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(.ultraThinMaterial)
    }
}

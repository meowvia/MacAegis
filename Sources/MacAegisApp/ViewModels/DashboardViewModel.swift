import Foundation
import SwiftUI
import Combine
import AppKit
import MacAegisCore

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var isScanning: Bool = false
    @Published public var scanProgressText: String = "就绪"
    @Published public var scanResult: ScanResult?
    @Published public var selectedItemIds: Set<String> = []
    @Published public var systemMetrics: SystemMetrics
    @Published public var mountedDrives: [MountedDriveInfo] = []
    @Published public var powerInfo: PowerAndThermalInfo
    @Published public var networkSpeed: NetworkSpeedInfo
    @Published public var thermalAndFan: ThermalAndFanStatus
    @Published public var isCleaning: Bool = false
    @Published public var cleanReport: CleanExecutionReport?
    @Published public var isRefreshingMetrics: Bool = false
    @Published public var isRefreshingScan: Bool = false
    @Published public var actionToastMessage: String?

    private let scanner = ScannerEngine()
    private let cleaner = CleanerEngine()
    private let diskDetector = DiskDetector.shared
    private let powerMonitor = PowerMonitor.shared
    private let networkMonitor = NetworkAndProxyMonitor.shared
    private let thermalDetector = ThermalAndFanDetector.shared
    private var telemetryTimer: AnyCancellable?

    public init() {
        self.systemMetrics = HardwareTelemetry.shared.fetchMetrics()
        self.mountedDrives = diskDetector.fetchMountedDrives()
        self.powerInfo = powerMonitor.fetchInfo()
        self.networkSpeed = networkMonitor.fetchNetworkSpeed()
        self.thermalAndFan = thermalDetector.fetchStatus()
        startTelemetryPolling()
    }

    private func startTelemetryPolling() {
        telemetryTimer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshTelemetry()
            }
    }

    public func refreshTelemetry() {
        self.systemMetrics = HardwareTelemetry.shared.fetchMetrics()
        self.mountedDrives = diskDetector.fetchMountedDrives()
        self.powerInfo = powerMonitor.fetchInfo()
        self.networkSpeed = networkMonitor.fetchNetworkSpeed()
        self.thermalAndFan = thermalDetector.fetchStatus()
    }

    public func manualRefresh() {
        isRefreshingMetrics = true
        refreshTelemetry()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.isRefreshingMetrics = false
        }
    }

    public func startScan() {
        guard !isScanning else { return }
        isScanning = true
        isRefreshingScan = true
        scanProgressText = "正在扫描系统与应用缓存..."
        scanResult = nil
        cleanReport = nil

        Task {
            let result = await scanner.scan { [weak self] item in
                Task { @MainActor in
                    self?.scanProgressText = "发现: \(item.name)"
                }
            }

            self.scanResult = result
            self.selectedItemIds = Set(result.items.filter { $0.safetyLevel == .safe }.map { $0.id })
            self.isScanning = false
            self.isRefreshingScan = false
            self.scanProgressText = "扫描完成"
        }
    }

    public var selectedTotalSizeBytes: Int64 {
        guard let result = scanResult else { return 0 }
        return result.items
            .filter { selectedItemIds.contains($0.id) }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    public var selectedFormattedSize: String {
        return ByteFormatter.format(selectedTotalSizeBytes)
    }

    public func toggleItemSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func selectAll() {
        guard let result = scanResult else { return }
        selectedItemIds = Set(result.items.map { $0.id })
    }

    public func deselectAll() {
        selectedItemIds.removeAll()
    }

    /// Single item deletion
    public func cleanSingleItem(_ item: CleanItem) {
        let report = cleaner.clean(items: [item], dryRun: false, useTrash: true)
        if report.successfulCount > 0 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                if let currentResult = self.scanResult {
                    let updatedItems = currentResult.items.filter { $0.id != item.id }
                    self.scanResult = ScanResult(items: updatedItems, durationSeconds: currentResult.durationSeconds)
                }
                self.selectedItemIds.remove(item.id)
                self.showToast("已将 \(item.name) 移至废纸篓")
            }
        }
    }

    /// Reveal file in Finder
    public func revealInFinder(path: String) {
        let expanded = FileUtils.expandPath(path)
        NSWorkspace.shared.selectFile(expanded, inFileViewerRootedAtPath: "")
    }

    /// Add to custom whitelist
    public func whitelistItem(_ item: CleanItem) {
        try? WhitelistManager.shared.addToWhitelist(path: item.path)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if let currentResult = self.scanResult {
                let updatedItems = currentResult.items.filter { $0.id != item.id }
                self.scanResult = ScanResult(items: updatedItems, durationSeconds: currentResult.durationSeconds)
            }
            self.selectedItemIds.remove(item.id)
            self.showToast("已将 \(item.name) 加入忽略白名单")
        }
    }

    private func showToast(_ msg: String) {
        self.actionToastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.actionToastMessage == msg {
                self?.actionToastMessage = nil
            }
        }
    }

    public func executeClean(useTrash: Bool = true) {
        guard let result = scanResult else { return }
        isCleaning = true

        let itemsToClean = result.items.map { item -> CleanItem in
            var updated = item
            updated.isSelected = selectedItemIds.contains(item.id)
            return updated
        }

        let report = cleaner.clean(items: itemsToClean, dryRun: false, useTrash: useTrash)
        self.cleanReport = report
        self.isCleaning = false
        self.showToast("已成功移入废纸篓 \(report.successfulCount) 项 (\(report.formattedReclaimed))")

        // Refresh scan after clean
        startScan()
    }
}

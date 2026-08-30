import Foundation
import SwiftUI
import Combine
import AppKit
import MacAegisCore

@MainActor
public final class UninstallerViewModel: ObservableObject {
    @Published public var installedApps: [AppDetector.InstalledApp] = []
    @Published public var appSizes: [URL: Int64] = [:]
    @Published public var searchText: String = ""
    @Published public var selectedBundle: AppUninstallBundle?
    @Published public var isAnalyzing: Bool = false
    @Published public var selectedItemIds: Set<String> = []
    @Published public var isUninstalling: Bool = false
    @Published public var alertMessage: String?
    @Published public var isSuccessToast: Bool = false
    @Published public var toastMessage: String?
    @Published public var isRefreshing: Bool = false

    private let appDetector = AppDetector.shared
    private let uninstaller = AppUninstaller.shared
    private let cleaner = CleanerEngine()
    private var sizeCalculationTask: Task<Void, Never>?

    public init() {
        loadInstalledApps()
    }

    public func loadInstalledApps() {
        isRefreshing = true
        sizeCalculationTask?.cancel()

        // 1. Instantaneous lightweight plist index on main thread (< 30ms)
        self.installedApps = appDetector.indexInstalledApps(forceRefresh: true)
            .filter { $0.bundleURL.path.hasPrefix("/Applications") || $0.bundleURL.path.hasPrefix(FileUtils.expandPath("~/Applications")) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        
        self.isRefreshing = false

        // 2. Asynchronous background size pre-warming (Zero UI blocking!)
        let appsToMeasure = self.installedApps
        sizeCalculationTask = Task.detached(priority: .background) { [weak self] in
            for app in appsToMeasure {
                if Task.isCancelled { break }
                let size = FileUtils.calculateSize(atPath: app.bundleURL.path)
                await MainActor.run {
                    self?.appSizes[app.bundleURL] = size
                }
            }
        }
    }

    public var filteredApps: [AppDetector.InstalledApp] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return installedApps
        }
        let query = searchText.lowercased()
        return installedApps.filter {
            $0.name.lowercased().contains(query) || ($0.bundleId?.lowercased().contains(query) ?? false)
        }
    }

    public func appSize(for app: AppDetector.InstalledApp) -> String {
        if let size = appSizes[app.bundleURL] {
            return ByteFormatter.format(size)
        }
        return "计算中..."
    }

    public func analyzeApp(url: URL) {
        isAnalyzing = true
        toastMessage = nil
        alertMessage = nil

        // Run deep directory analysis on background thread
        Task.detached(priority: .userInitiated) { [weak self] in
            let bundle = AppUninstaller.shared.analyzeApp(at: url)
            await MainActor.run {
                guard let self = self else { return }
                self.selectedBundle = bundle
                if let b = bundle {
                    self.selectedItemIds = Set(b.associatedItems.map { $0.id })
                }
                self.isAnalyzing = false
            }
        }
    }

    public var selectedTotalSize: Int64 {
        guard let bundle = selectedBundle else { return 0 }
        return bundle.associatedItems
            .filter { selectedItemIds.contains($0.id) }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    public var formattedSelectedSize: String {
        return ByteFormatter.format(selectedTotalSize)
    }

    public func toggleItemSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func executeUninstall() {
        guard let bundle = selectedBundle else { return }
        isUninstalling = true
        alertMessage = nil

        let itemsToDelete = bundle.associatedItems.filter { selectedItemIds.contains($0.id) }

        Task.detached(priority: .userInitiated) { [weak self] in
            // 1. Pre-flight check: Gracefully terminate running instances, fallback to forceTerminate (SIGKILL)
            let runningApps = NSWorkspace.shared.runningApplications
            var matchedRunning: [NSRunningApplication] = []
            for running in runningApps {
                if let bId = running.bundleIdentifier, let targetBId = bundle.bundleId, bId == targetBId {
                    matchedRunning.append(running)
                } else if running.bundleURL == bundle.appURL {
                    matchedRunning.append(running)
                }
            }

            for app in matchedRunning {
                app.terminate()
            }

            if !matchedRunning.isEmpty {
                // Poll up to 1.5s, then escalate to forceTerminate if still alive
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                for app in matchedRunning {
                    if !app.isTerminated {
                        app.forceTerminate()
                    }
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            // 2. Perform clean deletion
            let report = CleanerEngine().clean(items: itemsToDelete, useTrash: true)
            await MainActor.run {
                guard let self = self else { return }
                self.isUninstalling = false
                if report.failedCount == 0 {
                    SoundSentinel.shared.playWaterDropletChime()
                    self.toastMessage = "已成功彻底卸载「\(bundle.appName)」，释放 \(ByteFormatter.format(report.totalReclaimedBytes)) 空间 🌊"
                    self.selectedBundle = nil
                    self.loadInstalledApps()
                } else {
                    self.alertMessage = "卸载过程中部分受保护文件未能移除：\n" + report.errors.joined(separator: "\n")
                }
            }
        }
    }
}

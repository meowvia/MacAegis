import Foundation
import SwiftUI
import Combine
import AppKit
import MacAegisCore

@MainActor
public final class UninstallerViewModel: ObservableObject {
    public enum DisplayMode { case installedApps, orphans }
    @Published public var displayMode: DisplayMode = .installedApps
    @Published public var orphanLeftovers: [CleanItem] = []
    @Published public var isScanningOrphans: Bool = false
    @Published public var checkedOrphanIds: Set<String> = []

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

    @Published public var expandedAppUrls: Set<URL> = []
    @Published public var analyzedBundles: [URL: AppUninstallBundle] = [:]
    @Published public var analyzingAppUrls: Set<URL> = []
    @Published public var checkedAppUrls: Set<URL> = []
    @Published public var checkedItemIdsByApp: [URL: Set<String>] = [:]

    private let appDetector = AppDetector.shared
    private let uninstaller = AppUninstaller.shared
    private let cleaner = CleanerEngine()
    private var sizeCalculationTask: Task<Void, Never>?
    private var lastIndexTime: Date?

    public init() {
        // Run initial load asynchronously to completely prevent main thread stickiness on App launch / Language switch
        DispatchQueue.main.async {
            self.loadInstalledApps(forceRefresh: true)
        }
    }

    public func loadInstalledApps(forceRefresh: Bool = false) {
        // Performance Throttling: If apps already loaded within 10s and not forcing refresh,
        // reuse cache directly to provide 0ms tab switching!
        if !forceRefresh && !installedApps.isEmpty, let last = lastIndexTime, Date().timeIntervalSince(last) < 10.0 {
            return
        }

        isRefreshing = true
        sizeCalculationTask?.cancel()

        // 1. Instantaneous lightweight plist index on main thread (< 30ms)
        self.installedApps = appDetector.indexInstalledApps(forceRefresh: forceRefresh)
            .filter { $0.bundleURL.path.hasPrefix("/Applications") || $0.bundleURL.path.hasPrefix(FileUtils.expandPath("~/Applications")) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        
        AppIconCache.shared.preloadAsync(urls: self.installedApps.map { $0.bundleURL })

        self.lastIndexTime = Date()
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
        if let bundle = analyzedBundles[app.bundleURL] {
            let checked = checkedItemIdsByApp[app.bundleURL] ?? Set(bundle.associatedItems.map { $0.id })
            let activeSize = bundle.associatedItems.filter { checked.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
            return ByteFormatter.format(activeSize)
        }
        if let size = appSizes[app.bundleURL], size > 0 {
            return ByteFormatter.format(size)
        }
        return l10n("计算中...", "Calculating...")
    }

    public func isExpanded(url: URL) -> Bool {
        return expandedAppUrls.contains(url)
    }

    public func toggleAppExpansion(url: URL) {
        if expandedAppUrls.contains(url) {
            _ = withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                expandedAppUrls.remove(url)
            }
        } else {
            _ = withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                expandedAppUrls.insert(url)
            }
            if analyzedBundles[url] == nil {
                analyzingAppUrls.insert(url)
                Task.detached(priority: .userInitiated) { [weak self] in
                    let bundle = AppUninstaller.shared.analyzeApp(at: url)
                    await MainActor.run {
                        guard let self = self else { return }
                        if let b = bundle {
                            self.analyzedBundles[url] = b
                            if self.checkedItemIdsByApp[url] == nil {
                                self.checkedItemIdsByApp[url] = Set(b.associatedItems.map { $0.id })
                            }
                            self.checkedAppUrls.insert(url)
                        }
                        self.analyzingAppUrls.remove(url)
                    }
                }
            }
        }
    }

    // MARK: - Checkbox Logic for App and Subitems
    public func isAppChecked(url: URL) -> Bool {
        if let bundle = analyzedBundles[url] {
            guard !bundle.associatedItems.isEmpty else { return checkedAppUrls.contains(url) }
            let checked = checkedItemIdsByApp[url] ?? Set(bundle.associatedItems.map { $0.id })
            return checked.count == bundle.associatedItems.count
        }
        return checkedAppUrls.contains(url)
    }

    public func isAppPartiallyChecked(url: URL) -> Bool {
        if let bundle = analyzedBundles[url] {
            let checked = checkedItemIdsByApp[url] ?? Set(bundle.associatedItems.map { $0.id })
            return !checked.isEmpty && checked.count < bundle.associatedItems.count
        }
        return false
    }

    public func toggleAppCheck(url: URL) {
        if let bundle = analyzedBundles[url] {
            let currentlyChecked = isAppChecked(url: url)
            if currentlyChecked {
                checkedItemIdsByApp[url] = []
                checkedAppUrls.remove(url)
            } else {
                checkedItemIdsByApp[url] = Set(bundle.associatedItems.map { $0.id })
                checkedAppUrls.insert(url)
            }
        } else {
            if checkedAppUrls.contains(url) {
                checkedAppUrls.remove(url)
                checkedItemIdsByApp[url] = []
            } else {
                checkedAppUrls.insert(url)
                analyzingAppUrls.insert(url)
                Task.detached(priority: .userInitiated) { [weak self] in
                    let b = AppUninstaller.shared.analyzeApp(at: url)
                    await MainActor.run {
                        guard let self = self else { return }
                        if let b = b {
                            self.analyzedBundles[url] = b
                            self.checkedItemIdsByApp[url] = Set(b.associatedItems.map { $0.id })
                        }
                        self.analyzingAppUrls.remove(url)
                    }
                }
            }
        }
    }

    public func isItemChecked(appURL: URL, itemId: String) -> Bool {
        if let checked = checkedItemIdsByApp[appURL] {
            return checked.contains(itemId)
        }
        return true
    }

    public func toggleItemCheck(appURL: URL, itemId: String) {
        guard let bundle = analyzedBundles[appURL] else { return }
        var current = checkedItemIdsByApp[appURL] ?? Set(bundle.associatedItems.map { $0.id })
        if current.contains(itemId) {
            current.remove(itemId)
        } else {
            current.insert(itemId)
        }
        checkedItemIdsByApp[appURL] = current
        if current.isEmpty {
            checkedAppUrls.remove(appURL)
        } else {
            checkedAppUrls.insert(appURL)
        }
    }

    public func selectedItemsCount(for url: URL) -> Int {
        if let bundle = analyzedBundles[url] {
            let checked = checkedItemIdsByApp[url] ?? Set(bundle.associatedItems.map { $0.id })
            return bundle.associatedItems.filter { checked.contains($0.id) }.count
        }
        return 0
    }

    public func selectedSize(for app: AppDetector.InstalledApp) -> Int64 {
        if let bundle = analyzedBundles[app.bundleURL] {
            let checked = checkedItemIdsByApp[app.bundleURL] ?? Set(bundle.associatedItems.map { $0.id })
            return bundle.associatedItems.filter { checked.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
        }
        return appSizes[app.bundleURL] ?? 0
    }

    public func formattedSelectedSize(for app: AppDetector.InstalledApp) -> String {
        return ByteFormatter.format(selectedSize(for: app))
    }

    public func revealSubItemInFinder(path: String) {
        let expanded = FileUtils.expandPath(path)
        let fm = FileManager.default
        if fm.fileExists(atPath: expanded) {
            NSWorkspace.shared.selectFile(expanded, inFileViewerRootedAtPath: (expanded as NSString).deletingLastPathComponent)
            return
        }
        var current = (expanded as NSString).deletingLastPathComponent
        while current != "/" && !current.isEmpty {
            if fm.fileExists(atPath: current) {
                NSWorkspace.shared.selectFile(current, inFileViewerRootedAtPath: (current as NSString).deletingLastPathComponent)
                return
            }
            current = (current as NSString).deletingLastPathComponent
        }
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
                    self.analyzedBundles[url] = b
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
                // Wait up to 2.0s for graceful termination
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let stillRunning = matchedRunning.filter { !$0.isTerminated }
                if !stillRunning.isEmpty {
                    // Industrial Safety Baseline: Refuse to SIGKILL. Abort and protect unsaved work!
                    await MainActor.run {
                        guard let self = self else { return }
                        self.isUninstalling = false
                        self.alertMessage = l10n(
                            "应用「\(bundle.appName)」正在运行且可能有未保存的工作。为保障你的数据资产安全，已中止卸载，请先保存并手动退出该应用后再继续。",
                            "Application '\(bundle.appName)' is currently running and may have unsaved work. Uninstallation cancelled to protect your data. Please save and quit the application first."
                        )
                    }
                    return
                }
            }

            // Unload associated launch daemons/agents before file deletion
            AppUninstaller().preUninstallCleanup(items: itemsToDelete)

            // Precision defaults cleanup via XPC protocol (Strictly avoid killall cfprefsd)
            if let bId = bundle.bundleId, !bId.isEmpty {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
                proc.arguments = ["delete", bId]
                try? proc.run()
                proc.waitUntilExit()
            }

            // 2. Perform clean deletion
            let report = await CleanerEngine().clean(items: itemsToDelete, useTrash: true)
            await MainActor.run {
                guard let self = self else { return }
                self.isUninstalling = false
                if report.failedCount == 0 {
                    SoundSentinel.shared.playWaterDropletChime()
                    self.toastMessage = l10n(
                        "已成功彻底卸载「\(bundle.appName)」，释放 \(ByteFormatter.format(report.totalReclaimedBytes)) 空间 🌊",
                        "Successfully uninstalled '\(bundle.appName)', reclaimed \(ByteFormatter.format(report.totalReclaimedBytes)) space 🌊"
                    )
                    self.selectedBundle = nil
                    self.expandedAppUrls.remove(bundle.appURL)
                    self.analyzedBundles.removeValue(forKey: bundle.appURL)
                    self.checkedItemIdsByApp.removeValue(forKey: bundle.appURL)
                    self.checkedAppUrls.remove(bundle.appURL)
                    self.loadInstalledApps(forceRefresh: true)
                } else {
                    self.alertMessage = l10n("卸载过程中部分受保护文件未能移除：\n", "Some protected files could not be removed during uninstallation:\n") + report.errors.joined(separator: "\n")
                    // DO NOT loadInstalledApps here to prevent SwiftUI alert dimming deadlock
                }
            }
        }
    }

    public func executeUninstallForApp(url: URL) {
        guard let bundle = analyzedBundles[url] else {
            analyzeApp(url: url)
            return
        }
        let checked = checkedItemIdsByApp[url] ?? Set(bundle.associatedItems.map { $0.id })
        let itemsToDelete = bundle.associatedItems.filter { checked.contains($0.id) }
        guard !itemsToDelete.isEmpty else {
            alertMessage = l10n("未选中任何需要卸载的文件。", "No files selected for uninstallation.")
            return
        }

        isUninstalling = true
        alertMessage = nil

        Task.detached(priority: .userInitiated) { [weak self] in
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
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let stillRunning = matchedRunning.filter { !$0.isTerminated }
                if !stillRunning.isEmpty {
                    await MainActor.run {
                        guard let self = self else { return }
                        self.isUninstalling = false
                        self.alertMessage = l10n(
                            "应用「\(bundle.appName)」正在运行且可能有未保存的工作。为保障你的数据资产安全，已中止卸载，请先保存并手动退出该应用后再继续。",
                            "Application '\(bundle.appName)' is currently running and may have unsaved work. Uninstallation cancelled to protect your data. Please save and quit the application first."
                        )
                    }
                    return
                }
            }

            AppUninstaller().preUninstallCleanup(items: itemsToDelete)

            if let bId = bundle.bundleId, !bId.isEmpty {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
                proc.arguments = ["delete", bId]
                try? proc.run()
                proc.waitUntilExit()
            }

            let report = await CleanerEngine().clean(items: itemsToDelete, useTrash: true)
            await MainActor.run {
                guard let self = self else { return }
                self.isUninstalling = false
                if report.failedCount == 0 {
                    SoundSentinel.shared.playWaterDropletChime()
                    self.toastMessage = l10n(
                        "已成功彻底卸载「\(bundle.appName)」，释放 \(ByteFormatter.format(report.totalReclaimedBytes)) 空间 🌊",
                        "Successfully uninstalled '\(bundle.appName)', reclaimed \(ByteFormatter.format(report.totalReclaimedBytes)) space 🌊"
                    )
                    self.expandedAppUrls.remove(url)
                    self.analyzedBundles.removeValue(forKey: url)
                    self.checkedItemIdsByApp.removeValue(forKey: url)
                    self.checkedAppUrls.remove(url)
                    self.loadInstalledApps(forceRefresh: true)
                } else {
                    self.alertMessage = l10n("卸载过程中部分受保护文件未能移除：\n", "Some protected files could not be removed during uninstallation:\n") + report.errors.joined(separator: "\n")
                    // DO NOT loadInstalledApps here to prevent SwiftUI alert dimming deadlock
                }
            }
        }
    }
}

/// Thread-safe high-performance App icon in-memory cache with downsampling
public final class AppIconCache: @unchecked Sendable {
    public static let shared = AppIconCache()
    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 300
    }

    public func preloadAsync(urls: [URL]) {
        Task.detached(priority: .background) { [weak self] in
            for url in urls {
                _ = self?.icon(for: url)
            }
        }
    }

    public func fastCachedIcon(for url: URL) -> NSImage? {
        return cache.object(forKey: url as NSURL)
    }

    public func icon(for url: URL) -> NSImage {
        let nsUrl = url as NSURL
        if let cached = cache.object(forKey: nsUrl) {
            return cached
        }
        
        // Fast placeholder for immediate return if not cached, letting background task fill it? 
        // For simplicity and immediate memory fix, just do sync downsample here.
        let rawIcon = NSWorkspace.shared.icon(forFile: url.path)
        let targetSize = NSSize(width: 64, height: 64)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        rawIcon.draw(in: NSRect(origin: .zero, size: targetSize),
                     from: NSRect(origin: .zero, size: rawIcon.size),
                     operation: .copy,
                     fraction: 1.0)
        resizedImage.unlockFocus()
        
        cache.setObject(resizedImage, forKey: nsUrl)
        return resizedImage
    }
}
extension UninstallerViewModel {
    public func scanOrphans() {
        guard !isScanningOrphans else { return }
        isScanningOrphans = true
        orphanLeftovers.removeAll()
        checkedOrphanIds.removeAll()
        
        Task.detached(priority: .userInitiated) {
            let hunter = OrphanHunterRules()
            let orphans = await hunter.scan(onFoundItem: nil)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.orphanLeftovers = orphans.sorted(by: { $0.sizeBytes > $1.sizeBytes })
                for item in self.orphanLeftovers where item.isSelected {
                    self.checkedOrphanIds.insert(item.id)
                }
                self.isScanningOrphans = false
            }
        }
    }

    public func cleanSelectedOrphans() {
        let itemsToDelete = orphanLeftovers.filter { checkedOrphanIds.contains($0.id) }
        guard !itemsToDelete.isEmpty else { return }
        
        isUninstalling = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let report = await CleanerEngine().clean(items: itemsToDelete, useTrash: true)
            await MainActor.run {
                guard let self = self else { return }
                self.isUninstalling = false
                if report.failedCount == 0 {
                    SoundSentinel.shared.playWaterDropletChime()
                    self.toastMessage = l10n("成功清理 \(itemsToDelete.count) 个残留文件，释放 \(ByteFormatter.format(report.totalReclaimedBytes)) 空间 🌊", "Successfully cleaned \(itemsToDelete.count) leftovers, reclaimed \(ByteFormatter.format(report.totalReclaimedBytes)) 🌊")
                    self.scanOrphans() // rescan
                } else {
                    self.alertMessage = l10n("部分残留文件受系统保护未能移除。", "Some protected leftovers could not be removed.")
                }
            }
        }
    }
}

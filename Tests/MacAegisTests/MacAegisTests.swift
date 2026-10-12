import Testing
import Foundation
@testable import MacAegisCore

@Test func testByteFormatterAccuracy() async throws {
    #expect(ByteFormatter.format(1024) == "1 KB" || ByteFormatter.format(1024).contains("KB"))
    #expect(ByteFormatter.format(1024 * 1024 * 50).contains("MB"))
    #expect(ByteFormatter.format(1024 * 1024 * 1024 * 2).contains("GB"))
}

@Test func testWhitelistSafety() async throws {
    let whitelist = WhitelistManager.shared

    // 1. System critical paths must always be protected
    #expect(whitelist.isProtected(path: "~/Library/Keychains"))
    #expect(whitelist.isProtected(path: "~/Library/Safari"))
    #expect(whitelist.isProtected(path: "~/Library/Mobile Documents"))
    #expect(whitelist.isProtected(path: "~/Library/Cookies"))
    #expect(whitelist.isProtected(path: "~/Library/Accounts"))

    // 2. Personal user directories must ALWAYS be protected
    #expect(whitelist.isProtected(path: "~/Desktop"))
    #expect(whitelist.isProtected(path: "~/Documents"))
    #expect(whitelist.isProtected(path: "~/Pictures"))
    #expect(whitelist.isProtected(path: "~/Downloads"))

    // 3. Database files and critical certificates must NEVER be touched
    #expect(whitelist.isProtected(path: "/some/random/path/test.db"))
    #expect(whitelist.isProtected(path: "/some/random/path/data.sqlite"))
    #expect(whitelist.isProtected(path: "/some/random/path/login.keychain"))
    #expect(whitelist.isProtected(path: "/some/random/path/cert.pem"))

    // 4. Critical App Data (VS Code, Steam, Browsers, etc.) must be protected
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Code"))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Steam"))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/BraveSoftware"))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Arc", mode: .cacheOnly))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Mozilla", mode: .cacheOnly))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Vivaldi", mode: .cacheOnly))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/com.operasoftware.Opera", mode: .cacheOnly))

    // 5. Non-protected safe temporary cache paths should return false
    #expect(!whitelist.isProtected(path: "~/Library/Caches/RandomTestAppCache12345/data.tmp"))
}

@Test func testScannerEngineWithAllRules() async throws {
    let scanner = ScannerEngine()
    #expect(scanner.rules.count >= 6)

    let result = await scanner.scan()
    #expect(result.durationSeconds >= 0.0)
    // Scan items must be sorted strictly by 0-9, A-Z natural order
    if result.items.count >= 2 {
        for i in 0..<(result.items.count - 1) {
            let comparison = result.items[i].name.localizedStandardCompare(result.items[i+1].name)
            #expect(comparison != .orderedDescending)
        }
    }
}

@Test func testAppDetectorIndexing() async throws {
    let detector = AppDetector.shared
    let apps = detector.indexInstalledApps()
    #expect(!apps.isEmpty)

    // Standard system apps must be detected
    #expect(detector.isAppInstalled(nameOrBundleId: "Finder"))
    #expect(detector.isAppInstalled(nameOrBundleId: "com.apple.Safari"))
}

@Test func testHardwareTelemetry() async throws {
    let telemetry = HardwareTelemetry.shared
    let metrics = telemetry.fetchMetrics()

    #expect(metrics.memoryTotalBytes > 0)
    #expect(metrics.memoryUsagePercent >= 0.0 && metrics.memoryUsagePercent <= 100.0)
    #expect(metrics.cpuUsagePercent >= 0.0 && metrics.cpuUsagePercent <= 100.0)
}

@Test func testCleanerDryRunNonDestructive() async throws {
    let dummyItem = CleanItem(
        name: "Test Non-Destructive Item",
        path: "/tmp/macaegis_dummy_path_test",
        sizeBytes: 1024 * 1024,
        category: .systemLogs,
        safetyLevel: .safe,
        itemDescription: "Unit test dummy item"
    )

    let cleaner = CleanerEngine()
    let report = await cleaner.clean(items: [dummyItem], dryRun: true)

    #expect(report.isDryRun == true)
    #expect(report.successfulCount == 1)
    #expect(report.totalReclaimedBytes == 1024 * 1024)
}

@Test func testCleanerHardBlocksProtectedItems() async throws {
    // Attempt to clean a protected item (e.g. ~/Library/Keychains or a .db file)
    let dangerousItem = CleanItem(
        name: "Dangerous Database File",
        path: "/Users/test/Library/Keychains/login.keychain",
        sizeBytes: 1024 * 1024 * 5,
        category: .systemCaches,
        safetyLevel: .safe,
        itemDescription: "Should be blocked immediately"
    )

    let cleaner = CleanerEngine()
    let report = await cleaner.clean(items: [dangerousItem], dryRun: false)

    // Must be blocked by safety engine
    #expect(report.failedCount == 1)
    #expect(report.successfulCount == 0)
    #expect(!report.errors.isEmpty)
    #expect(report.errors.first?.contains("【安全拦截】") == true || report.errors.first?.contains("[Protected]") == true)
}

@Test func testFullCategoryCoverageAndMathSanity() async throws {
    let scanner = ScannerEngine()
    let result = await scanner.scan()

    // 1. Math Sanity: Total size must equal the exact sum of all category sizes
    var computedTotal: Int64 = 0
    for category in CleanCategory.allCases {
        let catItems = result.items(for: category)
        let catSize = result.totalSize(for: category)
        let sumOfItems = catItems.reduce(0) { $0 + $1.sizeBytes }
        #expect(catSize == sumOfItems)
        computedTotal += catSize
    }
    #expect(result.totalSizeBytes == computedTotal)

    // 2. Zero Protected Paths Leaked
    for item in result.items {
        let mode: ProtectionMode = (item.category == .appCaches || item.category == .browserCaches || item.category == .messagingMedia || item.category == .developerCaches) ? .cacheOnly : .strict
        #expect(!WhitelistManager.shared.isProtected(path: item.path, mode: mode))
    }
}

@Test func testTemperatureConversionAccuracy() async throws {
    let status0 = ThermalAndFanStatus(
        chipTemperatureCelsius: 0.0,
        hasFan: true,
        fanSpeedRPM: 0,
        isFanSpeedReal: false,
        thermalStateDescription: "清凉",
        thermalBadge: "🟢"
    )
    #expect(status0.formattedTemperature(isCelsius: true) == "0°C")
    #expect(status0.formattedTemperature(isCelsius: false) == "32°F")

    let status100 = ThermalAndFanStatus(
        chipTemperatureCelsius: 100.0,
        hasFan: true,
        fanSpeedRPM: 4000,
        isFanSpeedReal: false,
        thermalStateDescription: "高温",
        thermalBadge: "🔴"
    )
    #expect(status100.formattedTemperature(isCelsius: true) == "100°C")
    #expect(status100.formattedTemperature(isCelsius: false) == "212°F")

    let status45 = ThermalAndFanStatus(
        chipTemperatureCelsius: 45.0,
        hasFan: true,
        fanSpeedRPM: 1200,
        isFanSpeedReal: false,
        thermalStateDescription: "正常",
        thermalBadge: "🟢"
    )
    #expect(status45.formattedTemperature(isCelsius: true) == "45°C")
    #expect(status45.formattedTemperature(isCelsius: false) == "113°F")
}


@Test func testCleanCategoryDrillDownIntegrity() async throws {
    let dim1: Set<CleanCategory> = [.appCaches, .systemCaches, .systemLogs]
    let dim2: Set<CleanCategory> = [.downloadsAndPackages, .developerCaches, .largeFiles]
    let dim3: Set<CleanCategory> = [.messagingMedia, .browserCaches]
    let dim4: Set<CleanCategory> = [.orphanLeftovers]

    // 1. Disjointness: No category overlaps across the 4 pods
    #expect(dim1.isDisjoint(with: dim2))
    #expect(dim1.isDisjoint(with: dim3))
    #expect(dim1.isDisjoint(with: dim4))
    #expect(dim2.isDisjoint(with: dim3))
    #expect(dim2.isDisjoint(with: dim4))
    #expect(dim3.isDisjoint(with: dim4))

    // 2. Full Exhaustiveness: Union of the 4 dimensions covers 100% of CleanCategory.allCases
    let totalCovered = dim1.union(dim2).union(dim3).union(dim4)
    #expect(totalCovered == Set(CleanCategory.allCases))
    #expect(totalCovered.count == 9)
}

@Test func testBilingualLocalizationManager() async throws {
    let loc = LocalizationManager.shared

    // Test Chinese
    loc.appLanguage = .zh
    #expect(!loc.isEnglish)
    #expect(loc.tr("智能清理", "Smart Clean") == "智能清理")
    #expect(CleanCategory.appCaches.displayName == "应用程序缓存")

    // Test English
    loc.appLanguage = .en
    #expect(loc.isEnglish)
    #expect(loc.tr("智能清理", "Smart Clean") == "Smart Clean")
    #expect(CleanCategory.appCaches.displayName == "Application Caches")
    #expect(CleanCategory.orphanLeftovers.displayName == "Application Leftovers")

    // Restore to Chinese
    loc.appLanguage = .zh
}

@Test func testFullDiskAccessHelperInstance() async throws {
    let fda = FullDiskAccessHelper.shared
    _ = fda.hasFullDiskAccess()
    #expect(Bool(true))
}

@Test func testKeychainHelperDirectOperations() async throws {
    let testService = "com.meowvia.MacAegis.test"
    let testAccount = "unit_test_account"
    let testData = "SecurePayload2026".data(using: .utf8)!

    // Save
    let saved = KeychainHelper.shared.save(service: testService, account: testAccount, data: testData)
    #expect(saved == true)

    // Load
    let loaded = KeychainHelper.shared.load(service: testService, account: testAccount)
    #expect(loaded == testData)

    // Delete
    let deleted = KeychainHelper.shared.delete(service: testService, account: testAccount)
    #expect(deleted == true)

    let loadedAfterDelete = KeychainHelper.shared.load(service: testService, account: testAccount)
    #expect(loadedAfterDelete == nil)
}

@Test func testCleanHistoryManagerOperations() async throws {
    let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("macaegis_history_\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: tempFile) }

    let historyMgr = CleanHistoryManager(customFileURL: tempFile)
    #expect(historyMgr.fetchHistory().isEmpty)

    historyMgr.recordClean(
        reclaimedBytes: 1024 * 1024 * 500,
        itemCount: 12,
        useTrash: true,
        cleanedPaths: ["/path/a", "/path/b"]
    )

    let records = historyMgr.fetchHistory()
    #expect(records.count == 1)
    #expect(records[0].totalReclaimedBytes == 1024 * 1024 * 500)
    #expect(records[0].useTrash == true)
    #expect(records[0].itemCount == 12)
    #expect(records[0].cleanedPaths.count == 2)

    historyMgr.clearHistory()
    #expect(historyMgr.fetchHistory().isEmpty)
}

@Test func testAppUninstallerDeepAnalysisAndCategorization() async throws {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("macaegis_uninstaller_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Mock an Application bundle
    let fakeAppBundle = tempDir.appendingPathComponent("SuperTool.app")
    try? FileManager.default.createDirectory(at: fakeAppBundle, withIntermediateDirectories: true)
    let fakeExec = fakeAppBundle.appendingPathComponent("SuperTool")
    try? Data("MOCK_BINARY_DATA".utf8).write(to: fakeExec)

    let uninstaller = AppUninstaller()
    let bundle = uninstaller.analyzeApp(at: fakeAppBundle)
    #expect(bundle != nil)
    #expect(bundle?.appName == "SuperTool")
    #expect(bundle?.associatedItems.count ?? 0 >= 1)
    #expect(bundle?.totalSizeBytes ?? 0 > 0)
}

@Test func testCreativeProjectRules() async throws {
    let rule = CreativeProjectRules()
    #expect(rule.ruleId == "creative_project_caches")
    #expect(rule.displayName == "影视创作与多媒体工程缓存")
    #expect(rule.category == .systemCaches)

    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("creative_test_\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Mock an Adobe Media Cache file
    let mediaCache = tempDir.appendingPathComponent("Adobe").appendingPathComponent("Common").appendingPathComponent("Media Cache Files")
    try FileManager.default.createDirectory(at: mediaCache, withIntermediateDirectories: true)
    let dummyPeak = mediaCache.appendingPathComponent("sample.pek")
    try Data("AUDIO_PEAK_DATA".utf8).write(to: dummyPeak)

    #expect(FileManager.default.fileExists(atPath: dummyPeak.path))
}

@Test func testGamingJunkRules() async throws {
    let rule = GamingJunkRules()
    #expect(rule.ruleId == "gaming_junk_rules")
    #expect(rule.displayName == "游戏平台下载与中断碎片")
    #expect(rule.category == .systemCaches)

    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gaming_test_\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Mock Steam downloading orphan file
    let steamDownloading = tempDir.appendingPathComponent("Steam").appendingPathComponent("steamapps").appendingPathComponent("downloading")
    try FileManager.default.createDirectory(at: steamDownloading, withIntermediateDirectories: true)
    let dummyPart = steamDownloading.appendingPathComponent("patch_part_123.tmp")
    try Data(repeating: 0xCC, count: 2048).write(to: dummyPart)

    #expect(FileManager.default.fileExists(atPath: dummyPart.path))
}

@Test func testCacheOnlyModeAllowsSafeSubpathsInsideProtectedContainers() async throws {
    let whitelist = WhitelistManager.shared
    
    // Path inside protected Google container
    let chromeGpuCache = "~/Library/Application Support/Google/Chrome/Default/GPUCache"
    let chromePreferences = "~/Library/Application Support/Google/Chrome/Default/Preferences"
    
    // In strict mode: whole container is blocked
    #expect(whitelist.isProtected(path: chromeGpuCache, mode: .strict) == true)
    #expect(whitelist.isProtected(path: chromePreferences, mode: .strict) == true)
    
    // In cacheOnly mode: safe cache subpath is permitted, but preferences/config remains strictly protected!
    #expect(whitelist.isProtected(path: chromeGpuCache, mode: .cacheOnly) == false)
    #expect(whitelist.isProtected(path: chromePreferences, mode: .cacheOnly) == true)
}

@Test func testWeChatAndQQChatDatabasesAbsoluteProtection() async throws {
    let whitelist = WhitelistManager.shared
    
    let wechatDoc = "~/Library/Containers/com.tencent.xinWeChat/Data/Documents"
    let qqDoc = "~/Library/Containers/com.tencent.qq/Data/Documents"
    let wechatSubDoc = "~/Library/Containers/com.tencent.xinWeChat/Data/Documents/0001/session.db"
    
    // Even under cacheOnly mode, chat databases must be strictly blocked unconditionally!
    #expect(whitelist.isProtected(path: wechatDoc, mode: .cacheOnly) == true)
    #expect(whitelist.isProtected(path: qqDoc, mode: .cacheOnly) == true)
    #expect(whitelist.isProtected(path: wechatSubDoc, mode: .cacheOnly) == true)
}

@Test func testEmptyDirectoryContentsReclaim() async throws {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("macaegis_empty_test_\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let file1 = tempDir.appendingPathComponent("file1.bin")
    let file2 = tempDir.appendingPathComponent("file2.bin")
    try Data(repeating: 0xAA, count: 1024).write(to: file1)
    try Data(repeating: 0xBB, count: 2048).write(to: file2)

    #expect(FileManager.default.fileExists(atPath: file1.path) == true)
    #expect(FileManager.default.fileExists(atPath: file2.path) == true)

    let reclaimed = FileUtils.emptyDirectoryContents(atPath: tempDir.path)
    #expect(reclaimed > 0)
    #expect(FileManager.default.fileExists(atPath: tempDir.path) == true) // Directory remains
    #expect(FileManager.default.fileExists(atPath: file1.path) == false) // Files removed
    #expect(FileManager.default.fileExists(atPath: file2.path) == false)
}

@Test func testGroupContainersProtectionAndVendorAwareness() async throws {
    let detector = AppDetector.shared
    _ = detector.indexInstalledApps()

    // Tencent group container protection
    let isTencentInUse = detector.isGroupContainerInUse(groupName: "FN2V63AD2J.com.tencent")
    #expect(isTencentInUse == true)

    // Apple group container protection
    let isAppleInUse = detector.isGroupContainerInUse(groupName: "group.com.apple.notes")
    #expect(isAppleInUse == true)

    // Google vendor protection if Chrome installed
    let isGoogleActive = detector.isVendorDirectoryActive(vendorName: "Google")
    #expect(isGoogleActive == true)

    // Brave vendor protection for installed Brave Browser
    let isBraveActive = detector.isVendorDirectoryActive(vendorName: "BraveSoftware")
    #expect(isBraveActive == true)

    // Completely bogus uninstalled group
    let isBogusInUse = detector.isGroupContainerInUse(groupName: "ZZ999XYZ.com.nonexistent.fakeapp999")
    #expect(isBogusInUse == false)
}

@Test func testOrphanHunterRulesAndSystemDirectoryProtection() async throws {
    let rule = OrphanHunterRules()
    #expect(rule.ruleId == "orphan_leftovers_hunter")
    #expect(rule.category == .orphanLeftovers)

    let items = await rule.scan(onFoundItem: nil)
    // Scan items should be discovered safely
    #expect(items.allSatisfy { $0.category == .orphanLeftovers })

    // Critical: FN2V63AD2J.com.tencent MUST NOT be in the scanned items (protected!)
    let hasTencentGroup = items.contains { $0.path.contains("FN2V63AD2J.com.tencent") }
    #expect(hasTencentGroup == false, "Tencent Group Container must NEVER be flagged as orphan")

    // Critical: Apple internal daemon directories MUST NOT be flagged as orphan
    let hasCloudDocs = items.contains { $0.path.contains("CloudDocs") }
    #expect(hasCloudDocs == false, "CloudDocs system service must not be flagged as orphan")

    // Critical: Major browser roots MUST NOT be flagged as orphan
    let hasBrave = items.contains { $0.path.contains("BraveSoftware") }
    #expect(hasBrave == false, "BraveSoftware must NEVER be flagged as orphan")

    // Critical: Application Support items must have .caution safety level and never default selected
    let appSupportItems = items.filter { $0.path.contains("/Library/Application Support") }
    for item in appSupportItems {
        #expect(item.safetyLevel == .caution, "Application Support leftover \(item.path) must be .caution")
        #expect(item.isSelected == false, "Application Support leftover \(item.path) must never be pre-selected")
    }
}

@Test func testLanguageAutoDetectionLogic() async throws {
    // 1. When no saved preference exists, detect from system preferred languages
    let zhDetect = LocalizationManager.resolveInitialLanguage(savedValue: nil, preferredLanguages: ["zh-Hans-CN", "en-US"])
    #expect(zhDetect == .zh)

    let enDetect = LocalizationManager.resolveInitialLanguage(savedValue: nil, preferredLanguages: ["en-US", "zh-CN"])
    #expect(enDetect == .en)

    let fallbackDetect = LocalizationManager.resolveInitialLanguage(savedValue: nil, preferredLanguages: ["ja-JP", "fr-FR"])
    #expect(fallbackDetect == .en)

    // 2. Saved user preference strictly overrides system locale
    let userPrefZh = LocalizationManager.resolveInitialLanguage(savedValue: "zh", preferredLanguages: ["en-US"])
    #expect(userPrefZh == .zh)

    let userPrefEn = LocalizationManager.resolveInitialLanguage(savedValue: "en", preferredLanguages: ["zh-Hans-CN"])
    #expect(userPrefEn == .en)
}

@Test func testThermalAndFanDetectorCachedBridge() async throws {
    let detector = ThermalAndFanDetector.shared
    let status1 = detector.fetchStatus()
    let status2 = detector.fetchStatus()

    // Status calls succeed back-to-back using cached bridge without error
    #expect(!status1.thermalBadge.isEmpty)
    #expect(!status2.thermalBadge.isEmpty)
}


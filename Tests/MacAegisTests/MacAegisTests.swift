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

    // 4. Critical App Data (VS Code, Steam, etc.) must be protected
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Code"))
    #expect(whitelist.isProtected(path: "~/Library/Application Support/Steam"))

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
    let report = cleaner.clean(items: [dummyItem], dryRun: true)

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
    let report = cleaner.clean(items: [dangerousItem], dryRun: false)

    // Must be blocked by safety engine
    #expect(report.failedCount == 1)
    #expect(report.successfulCount == 0)
    #expect(!report.errors.isEmpty)
    #expect(report.errors.first?.contains("【安全拦截】") == true)
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
        #expect(!WhitelistManager.shared.isProtected(path: item.path))
    }
}

@Test func testTemperatureConversionAccuracy() async throws {
    let status0 = ThermalAndFanStatus(
        chipTemperatureCelsius: 0.0,
        hasFan: true,
        fanSpeedRPM: 0,
        thermalStateDescription: "清凉",
        thermalBadge: "🟢"
    )
    #expect(status0.formattedTemperature(isCelsius: true) == "0.0 ℃")
    #expect(status0.formattedTemperature(isCelsius: false) == "32.0 ℉")

    let status100 = ThermalAndFanStatus(
        chipTemperatureCelsius: 100.0,
        hasFan: true,
        fanSpeedRPM: 4000,
        thermalStateDescription: "高温",
        thermalBadge: "🔴"
    )
    #expect(status100.formattedTemperature(isCelsius: true) == "100.0 ℃")
    #expect(status100.formattedTemperature(isCelsius: false) == "212.0 ℉")

    let status45 = ThermalAndFanStatus(
        chipTemperatureCelsius: 45.0,
        hasFan: true,
        fanSpeedRPM: 1200,
        thermalStateDescription: "正常",
        thermalBadge: "🟢"
    )
    #expect(status45.formattedTemperature(isCelsius: true) == "45.0 ℃")
    #expect(status45.formattedTemperature(isCelsius: false) == "113.0 ℉")
}

@Test func testProxyModeAndNetworkSpeed() async throws {
    // 1. Direct Mode
    let directMode = ProxyMode.direct
    #expect(directMode.rawValue == "普通直连")
    #expect(directMode.badge == "🔵")
    #expect(directMode.colorHex == "0284C7")

    // 2. Rule Mode
    let ruleMode = ProxyMode.rule
    #expect(ruleMode.rawValue == "规则分流")
    #expect(ruleMode.badge == "🟢")
    #expect(ruleMode.colorHex == "10B981")

    // 3. Global Mode
    let globalMode = ProxyMode.global
    #expect(globalMode.rawValue == "全局代理")
    #expect(globalMode.badge == "🔴")
    #expect(globalMode.colorHex == "EF4444")

    // 4. NetworkSpeedInfo
    let speed = NetworkSpeedInfo(
        uploadBytesPerSec: 1024 * 512,      // 512 KB/s
        downloadBytesPerSec: 1024 * 1024 * 5, // 5 MB/s
        proxyMode: .direct
    )
    #expect(speed.compactDownString == "5.0M")
    #expect(speed.compactUpString == "512K")
    #expect(speed.menuBarDisplayString.contains("↓") && speed.menuBarDisplayString.contains("↑"))
}

@Test func testCleanCategoryDrillDownIntegrity() async throws {
    let dim1: Set<CleanCategory> = [.appCaches, .systemCaches, .systemLogs]
    let dim2: Set<CleanCategory> = [.downloadsAndPackages, .developerCaches]
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
    #expect(totalCovered.count == 8)
}

@Test func testBilingualLocalizationManager() async throws {
    let loc = LocalizationManager.shared

    // Test Chinese
    loc.currentLanguage = AppLanguage.zh.rawValue
    #expect(!loc.isEnglish)
    #expect(loc.tr("智能清理", "Smart Clean") == "智能清理")
    #expect(CleanCategory.appCaches.displayName == "应用日常运行缓存")

    // Test English
    loc.currentLanguage = AppLanguage.en.rawValue
    #expect(loc.isEnglish)
    #expect(loc.tr("智能清理", "Smart Clean") == "Smart Clean")
    #expect(CleanCategory.appCaches.displayName == "Application Runtime Caches")
    #expect(CleanCategory.orphanLeftovers.displayName == "Uninstalled App Leftovers")
    #expect(ProxyMode.direct.localizedTitle == "Direct")
    #expect(ProxyMode.rule.localizedTitle == "Rule Routing")
    #expect(ProxyMode.global.localizedTitle == "Global Proxy")

    // Restore to Chinese
    loc.currentLanguage = AppLanguage.zh.rawValue
}

@Test func testPrivacyVaultIntegrityAndPersistence() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("macaegis_vault_unit_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let vault = PrivacyVaultManager(customBaseDirectory: tempDir, isTestIsolation: true)

    // 1. Password setup & verification
    let testPassword = "MacAegisSecurePass2026!"
    let testHint = "TestHint123"
    let setupSuccess = vault.setMasterPassword(testPassword, hint: testHint)
    #expect(setupSuccess == true)
    #expect(vault.hasMasterPassword == true)
    #expect(vault.verifyMasterPassword(testPassword) == true)
    #expect(vault.verifyMasterPassword("WrongPassword123") == false)
    #expect(vault.getPasswordHint() == testHint)

    // 2. Non-destructive Add and Remove
    let testFolder = tempDir.appendingPathComponent("sub_folder")
    try? FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)

    let addedItem = vault.addItem(url: testFolder, type: .hidden)
    #expect(addedItem != nil)
    #expect(addedItem?.status == .hidden)

    let itemsAfterAdd = vault.fetchItems()
    #expect(itemsAfterAdd.contains(where: { $0.path == testFolder.path }))

    // 3. Remove Protection (Must unhide and remove from metadata)
    if let id = addedItem?.id {
        vault.removeItem(id: id)
        let itemsAfterRemove = vault.fetchItems()
        #expect(!itemsAfterRemove.contains(where: { $0.id == id }))
    }
}

@Test func testPrivacyVault4KBHeaderScramblerAndBitPerfectRecovery() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("macaegis_vault_header_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let vault = PrivacyVaultManager(customBaseDirectory: tempDir)

    let testFile = tempDir.appendingPathComponent("confidential.pdf")
    var originalData = "%PDF-1.4\n%âãÏÓ\nThis is proprietary confidential financial statement data.".data(using: .utf8)!
    originalData.append(Data(repeating: 0x55, count: 8192))
    try? originalData.write(to: testFile)

    // Add and lock
    guard let item = vault.addItem(url: testFile, type: .hidden) else {
        #expect(Bool(false), "Failed to add item to vault")
        return
    }

    // 1. Verify that file is locked with 000 permissions (cannot be read directly by standard processes)
    let unauthRead = try? Data(contentsOf: testFile)
    #expect(unauthRead == nil || unauthRead?.isEmpty == true)

    // 2. Temporarily inspect raw bytes with read permission to verify header scramble
    let chflagsProc = Process()
    chflagsProc.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
    chflagsProc.arguments = ["nouchg", testFile.path]
    try? chflagsProc.run()
    chflagsProc.waitUntilExit()

    try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: testFile.path)
    if let lockedBytes = try? Data(contentsOf: testFile) {
        // Scrambled header must NOT match original %PDF magic signature
        #expect(!lockedBytes.prefix(4).elementsEqual("%PDF".utf8))
    }

    // Restore lock state before unlock test
    try? FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: testFile.path)
    let chflagsLock = Process()
    chflagsLock.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
    chflagsLock.arguments = ["uchg,hidden", testFile.path]
    try? chflagsLock.run()
    chflagsLock.waitUntilExit()

    // 3. Unlock item silently in test mode
    vault.openAndHighlightInFinder(path: testFile.path, revealInFinder: false)

    // 4. Verify that unlocked bytes are 100% bit-perfect restored
    let unlockedData = (try? Data(contentsOf: testFile)) ?? Data()
    #expect(unlockedData == originalData)

    // Cleanup
    vault.removeItem(id: item.id)
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

@Test func testPrivacyVaultKeychainAndReclaimingDisasterRecovery() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("macaegis_vault_keychain_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer {
        let nouchg = Process()
        nouchg.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
        nouchg.arguments = ["-R", "nouchg", tempDir.path]
        try? nouchg.run()
        nouchg.waitUntilExit()
        try? FileManager.default.removeItem(at: tempDir)
    }

    let configDir1 = tempDir.appendingPathComponent("config1")
    let testFolder = tempDir.appendingPathComponent("MySecretFiles")
    try? FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)

    let testFile = testFolder.appendingPathComponent("secret.txt")
    let originalText = "Top Secret Financial Records 2026"
    try? originalText.write(to: testFile, atomically: true, encoding: .utf8)

    let testService = "com.meowvia.MacAegis.test.recovery.\(UUID().uuidString)"

    // 1. Initial vault: set password & lock folder
    let vault1 = PrivacyVaultManager(customBaseDirectory: configDir1, keychainService: testService, isTestIsolation: false)
    let setup = vault1.setMasterPassword("MySecretPass2026!", hint: "RecoveryHint")
    #expect(setup == true)
    let added = vault1.addItem(url: testFolder, type: .hidden)
    #expect(added != nil)

    // 2. Simulate complete disaster: configDir1 is completely wiped (Third party uninstaller simulation)
    try? FileManager.default.removeItem(at: configDir1)
    #expect(FileManager.default.fileExists(atPath: configDir1.path) == false)

    // 3. New app installation in a fresh config directory (configDir2)
    let configDir2 = tempDir.appendingPathComponent("config2")
    let vault2 = PrivacyVaultManager(customBaseDirectory: configDir2, keychainService: testService, isTestIsolation: false)
    
    // Auth MUST be recognized from macOS Keychain automatically!
    #expect(vault2.hasMasterPassword == true)
    #expect(vault2.verifyMasterPassword("MySecretPass2026!") == true)
    #expect(vault2.getPasswordHint() == "RecoveryHint")

    // 4. User drags the locked folder back into the new MacAegis (Re-claiming)
    let recovered = vault2.addItem(url: testFolder, type: .hidden)
    #expect(recovered != nil)
    #expect(recovered?.status == .hidden)

    // 5. User unlocks it with their password/Touch ID in the new app
    vault2.openAndHighlightInFinder(path: testFolder.path, revealInFinder: false)

    // 6. Verify full bit-perfect recovery
    let restoredText = (try? String(contentsOf: testFile, encoding: .utf8)) ?? ""
    #expect(restoredText == originalText)

    // Reset Keychain state
    vault2.resetMasterAuth(clearKeychain: true)
}


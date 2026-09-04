import Foundation

public struct GamingJunkRules: CleanRuleProtocol {
    public let ruleId = "gaming_junk_rules"
    public let displayName = "游戏平台下载与中断碎片"
    public let category = CleanCategory.systemCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared
        let privacyVault = PrivacyVaultManager.shared

        // 1. Steam internal & external downloading fragments and shaders
        var steamRoots: [String] = [
            FileUtils.expandPath("~/Library/Application Support/Steam")
        ]

        let mountedDrives = DiskDetector.shared.fetchMountedDrives()
        for drive in mountedDrives {
            let candidate = (drive.mountPath as NSString).appendingPathComponent("SteamLibrary")
            if fileManager.fileExists(atPath: candidate) {
                steamRoots.append(candidate)
            }
        }

        for sRoot in steamRoots {
            let targets: [(name: String, subPath: String, desc: String)] = [
                ("Steam 下载中断残留孤儿分块 (downloading)", "steamapps/downloading", "Steam 网络中断或异常退出后遗留的未完成安装包分片，可安全清理"),
                ("Steam 临时解包中间件 (temp)", "steamapps/temp", "Steam 游戏安装解包产生的临时校验文件"),
                ("Steam 着色器预编译缓存 (shadercache)", "steamapps/shadercache", "显卡着色器预编译暂存，游戏启动时可按需重新生成")
            ]

            for target in targets {
                let fullPath = (sRoot as NSString).appendingPathComponent(target.subPath)
                if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) && !privacyVault.isLockedForScanSkip(path: fullPath) {
                    let size = FileUtils.calculateSize(atPath: fullPath)
                    if size > 5_000_000 { // > 5MB
                        let driveLabel = sRoot.hasPrefix("/Volumes/") ? " [外置盘]" : ""
                        let item = CleanItem(
                            name: "\(target.name)\(driveLabel)",
                            path: fullPath,
                            sizeBytes: size,
                            category: .systemCaches,
                            safetyLevel: .safe,
                            itemDescription: target.desc,
                            isSelected: true
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // 2. Epic Games & Launcher WebCache
        let epicTargets: [(name: String, path: String, desc: String)] = [
            ("Epic Games 启动器网页与静态流缓存", "~/Library/Caches/com.epicgames.EpicGamesLauncher", "Epic 商城页面与静态缩略图缓存"),
            ("Epic Games 保存的 Web 缓存", "~/Library/Application Support/Epic/EpicGamesLauncher/Saved/webcache", "Epic 客户端内置 WebKit 临时浏览数据")
        ]

        for target in epicTargets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) && !privacyVault.isLockedForScanSkip(path: fullPath) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 5_000_000 {
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: .systemCaches,
                        safetyLevel: .safe,
                        itemDescription: target.desc,
                        isSelected: true
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        return items
    }
}

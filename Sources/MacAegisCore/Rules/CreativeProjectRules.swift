import Foundation

public struct CreativeProjectRules: CleanRuleProtocol {
    public let ruleId = "creative_project_caches"
    public let displayName = "影视创作与多媒体工程缓存"
    public let category = CleanCategory.systemCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared
        let privacyVault = PrivacyVaultManager.shared

        // 1. Adobe Premiere Pro & After Effects Media Cache Files
        let targets: [(name: String, path: String, desc: String)] = [
            ("Adobe 媒体渲染与音频峰值缓存", "~/Library/Application Support/Adobe/Common/Media Cache Files", "Premiere Pro / After Effects 生成的音视频预览切片与媒体加速缓存，可随时安全重建"),
            ("Adobe 峰值数据索引 (Peak Files)", "~/Library/Application Support/Adobe/Common/Peak Files", "音频波形峰值采样缓存，清理后重新载入项目时可自动重建"),
            ("DaVinci Resolve 优化媒体与切片缓存", "~/Library/Application Support/Blackmagic Design/DaVinci Resolve/CacheClip", "达芬奇剪辑项目渲染节点与优化媒体切片"),
            ("剪映专业版草稿渲染缓存", "~/Movies/JianyingPro/User Data/Projects", "剪映历史导出草稿生成的临时渲染片段"),
            ("CapCut 媒体预览切片", "~/Movies/CapCut/User Data/Cache", "CapCut 桌面端视频预览切片与时间线缓存")
        ]

        for target in targets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) && !privacyVault.isLockedForScanSkip(path: fullPath) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 5_000_000 { // > 5MB
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

        // 2. Final Cut Pro .fcpbundle Render Files inspection
        let searchRoots = [
            FileUtils.expandPath("~/Movies"),
            FileUtils.expandPath("~/Documents")
        ]

        for root in searchRoots {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: root) else { continue }
            for sub in contents where sub.hasSuffix(".fcpbundle") {
                let bundlePath = (root as NSString).appendingPathComponent(sub)
                let renderFilesPath = (bundlePath as NSString).appendingPathComponent("Render Files")
                if fileManager.fileExists(atPath: renderFilesPath) && !whitelist.isProtected(path: renderFilesPath) && !privacyVault.isLockedForScanSkip(path: renderFilesPath) {
                    let renderSize = FileUtils.calculateSize(atPath: renderFilesPath)
                    if renderSize > 50_000_000 { // > 50MB
                        let item = CleanItem(
                            name: "Final Cut Pro 渲染中间件「\(sub)」",
                            path: renderFilesPath,
                            sizeBytes: renderSize,
                            category: .systemCaches,
                            safetyLevel: .safe,
                            itemDescription: "FCP 历史 ProRes 渲染切片与光流分析文件，项目成片导出后可安全释放",
                            isSelected: true
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        return items
    }
}

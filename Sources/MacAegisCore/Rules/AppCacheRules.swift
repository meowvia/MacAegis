import Foundation

public struct AppCacheRules: CleanRuleProtocol {
    public let ruleId = "app_daily_caches"
    public let displayName = "应用与浏览器日常网络缓存"
    public let category = CleanCategory.appCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared
        let userCachesPath = FileUtils.expandPath("~/Library/Caches")

        guard fileManager.fileExists(atPath: userCachesPath) else { return items }

        // Specific targeted 100% safe browser and media network caches
        let knownTargets: [(name: String, subpath: String, desc: String, safety: SafetyLevel)] = [
            ("Google Chrome 网页与流媒体临时缓存", "~/Library/Caches/Google/Chrome", "Chrome 浏览网页时缓存的图片与静态资源，不影响书签、历史与密码", .safe),
            ("Microsoft Edge 网页渲染缓存", "~/Library/Caches/Microsoft Edge", "Edge 浏览器日常临时渲染数据与页面缓存", .safe),
            ("Arc 浏览器网页缓存", "~/Library/Caches/company.thebrowser.Browser", "Arc 浏览器临时网页静态资源缓存", .safe),
            ("Safari 网页与网站图标缓存", "~/Library/Caches/com.apple.Safari", "Safari 浏览时生成的临时网络与网站图标缓存", .safe),
            ("Spotify 离线流媒体临时切片", "~/Library/Caches/com.spotify.client", "Spotify 播放时预先加载的音频流缓存", .safe)
        ]

        var scannedPaths = Set<String>()

        for target in knownTargets {
            let fullPath = FileUtils.expandPath(target.subpath)
            scannedPaths.insert(fullPath)

            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath, mode: .cacheOnly) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 10_000_000 { // > 10MB
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: .appCaches,
                        safetyLevel: target.safety,
                        itemDescription: target.desc
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        // Generic scan for other heavy ~/Library/Caches entries (> 50MB)
        if let subdirs = try? fileManager.contentsOfDirectory(atPath: userCachesPath) {
            for sub in subdirs {
                let subPath = (userCachesPath as NSString).appendingPathComponent(sub)
                if scannedPaths.contains(subPath) || whitelist.isProtected(path: subPath, mode: .cacheOnly) {
                    continue
                }

                // Skip Apple system internal caches to be extra conservative
                if sub.hasPrefix("com.apple.") || sub.hasPrefix(".") { continue }

                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: subPath, isDirectory: &isDir) && isDir.boolValue {
                    let size = FileUtils.calculateSize(atPath: subPath)
                    if size > 50_000_000 { // > 50MB
                        let item = CleanItem(
                            name: "\(sub) 应用临时缓存",
                            path: subPath,
                            sizeBytes: size,
                            category: .appCaches,
                            safetyLevel: .safe,
                            itemDescription: "该第三方应用在日常运行中积累的临时磁盘缓存。"
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

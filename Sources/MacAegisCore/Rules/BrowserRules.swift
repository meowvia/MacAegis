import Foundation

public struct BrowserRules: CleanRuleProtocol {
    public let ruleId = "browser_deep_caches"
    public let displayName = "浏览器深度渲染与离线缓存"
    public let category = CleanCategory.browserCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared

        let browserTargets: [(name: String, path: String, desc: String, appName: String, safety: SafetyLevel)] = [
            // 1. Google Chrome
            ("Google Chrome 核心网络与图片缓存", "~/Library/Caches/Google/Chrome", "Chrome 网页图片、脚本与静态资源缓存", "Google Chrome", .safe),
            ("Chrome Service Worker 离线缓存", "~/Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage", "Chrome 网页离线常驻与预加载缓存", "Google Chrome", .safe),
            ("Chrome GPU 硬件加速着色器缓存", "~/Library/Application Support/Google/Chrome/Default/GPUCache", "Chrome 显卡硬件加速着色器缓存", "Google Chrome", .safe),
            ("Chrome 脚本预编译代码缓存", "~/Library/Application Support/Google/Chrome/Default/Service Worker/ScriptCache", "Chrome 预编译 JS 脚本中间件", "Google Chrome", .safe),

            // 2. Safari
            ("Safari 网页离线与网站图标缓存", "~/Library/Caches/com.apple.Safari", "Safari 浏览时生成的临时网络与网站 Favicon 缓存", "Safari", .safe),
            ("Safari 网页预览缩略图", "~/Library/Containers/com.apple.Safari/Data/Library/Caches", "Safari 历史记录与标签页缩略图快照", "Safari", .safe),

            // 3. Microsoft Edge
            ("Microsoft Edge 网页与离线存储缓存", "~/Library/Caches/Microsoft Edge", "Edge 浏览器日常临时渲染数据与页面缓存", "Microsoft Edge", .safe),
            ("Microsoft Edge GPU 着色器缓存", "~/Library/Application Support/Microsoft Edge/Default/GPUCache", "Edge 硬件渲染缓存", "Microsoft Edge", .safe),

            // 4. Arc / Brave / Opera
            ("Arc 浏览器网页与渲染缓存", "~/Library/Caches/company.thebrowser.Browser", "Arc 浏览器临时网页静态资源与工作区缓存", "Arc", .safe),
            ("Brave 浏览器网页离线缓存", "~/Library/Caches/BraveSoftware/Brave-Browser", "Brave 隐私浏览器临时离线网络包", "Brave", .safe)
        ]

        for target in browserTargets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 1_000_000 { // > 1MB
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: .browserCaches,
                        safetyLevel: target.safety,
                        itemDescription: target.desc,
                        associatedAppName: target.appName,
                        isSelected: target.safety == .safe
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        return items
    }
}

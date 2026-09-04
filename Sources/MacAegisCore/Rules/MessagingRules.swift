import Foundation

public struct MessagingRules: CleanRuleProtocol {
    public let ruleId = "messaging_media_rules"
    public let displayName = "即时通讯与多媒体流缓存"
    public let category = CleanCategory.messagingMedia

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared

        let targets: [(name: String, path: String, desc: String, appName: String, safety: SafetyLevel)] = [
            // 1. Telegram (Swift Native & Desktop)
            ("Telegram 离线媒体与视频缓存", "~/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/appstore", "Telegram 群组与频道查看过的 4K 视频、图片流，云端已永久保存，可随时安全释放", "Telegram", .safe),
            ("Telegram Desktop 媒体流缓存", "~/Library/Application Support/Telegram Desktop/tdata/user_data/media_cache", "Telegram 桌面端下载的媒体流缓存", "Telegram", .safe),
            ("Telegram 应用运行缓存", "~/Library/Caches/ru.keepcoder.Telegram", "Telegram 原生客户端网络与临时预览缓存", "Telegram", .safe),

            // 2. WhatsApp
            ("WhatsApp 临时媒体与网络缓存", "~/Library/Containers/net.whatsapp.WhatsApp/Data/Library/Caches", "WhatsApp 客户端接收的临时缩略图与网络流", "WhatsApp", .safe),
            ("WhatsApp 渲染与 GPU 缓存", "~/Library/Application Support/WhatsApp/Cache", "WhatsApp 界面渲染与代码缓存", "WhatsApp", .safe),

            // 3. Discord
            ("Discord 语音与群聊媒体缓存", "~/Library/Application Support/discord/Cache", "Discord 服务器频道中查看过的表情包、音视频与群文件预览", "Discord", .safe),
            ("Discord GPU 渲染中间件", "~/Library/Application Support/discord/GPUCache", "Discord 硬件加速着色器缓存", "Discord", .safe),

            // 4. Slack
            ("Slack 工作空间媒体与附件缓存", "~/Library/Application Support/Slack/Service Worker/CacheStorage", "Slack 频道内查看的办公文档缩略图与消息离线流", "Slack", .safe),
            ("Slack 客户端运行缓存", "~/Library/Caches/com.tinyspeck.slackmacgap", "Slack 应用运行临时数据", "Slack", .safe),

            // 5. Signal
            ("Signal 临时媒体渲染流", "~/Library/Application Support/Signal/Cache", "Signal 客户端离线媒体流", "Signal", .safe),

            // 6. 微信 (WeChat) - 仅清理纯运行与网页缓存，绝对物理排除 Documents 核心聊天数据库
            ("微信 运行与网页临时缓存", "~/Library/Containers/com.tencent.xinWeChat/Data/Library/Caches", "微信公众号网页、表情包缩略图与临时运行包 (绝对不包含聊天记录与文件)", "WeChat", .safe),
            ("微信 客户端系统缓存", "~/Library/Caches/com.tencent.xinWeChat", "微信 macOS 客户端临时网络会话缓存", "WeChat", .safe),

            // 7. QQ - 仅清理纯临时缓存，绝对物理排除 Documents 核心数据库
            ("QQ 运行与离线网页缓存", "~/Library/Containers/com.tencent.qq/Data/Library/Caches", "QQ 客户端临时预览文件与表情缓存 (绝对不包含核心聊天记录)", "QQ", .safe),
            ("QQ 客户端系统缓存", "~/Library/Caches/com.tencent.qq", "QQ macOS 客户端临时网络会话缓存", "QQ", .safe),

            // 8. 飞书 (Feishu / Lark) & 钉钉 (DingTalk)
            ("飞书 离线文档与音视频缓存", "~/Library/Application Support/Feishu/app_cache", "飞书工作群文件离线预览与会议临时数据", "Feishu", .safe),
            ("钉钉 办公群文件与媒体缓存", "~/Library/Application Support/DingTalkMac/Cache", "钉钉工作群内临时下载的预览图片与文档", "DingTalk", .safe),

            // 9. Zoom & Microsoft Teams
            ("Zoom 会议临时诊断日志与缓存", "~/Library/Application Support/zoom.us/data", "Zoom 视频会议产生的临时网络记录与转录缓存", "zoom.us", .safe),
            ("Microsoft Teams 团队离线媒体", "~/Library/Application Support/Microsoft/Teams/Cache", "Teams 频道音视频与文档缩略图缓存", "Microsoft Teams", .safe)
        ]

        for target in targets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath, mode: .cacheOnly) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 1_000_000 { // > 1MB
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: .messagingMedia,
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

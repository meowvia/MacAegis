import Foundation

public enum CleanCategory: String, CaseIterable, Codable, Sendable {
    case messagingMedia = "messaging_media"
    case developerCaches = "developer_caches"
    case browserCaches = "browser_caches"
    case downloadsAndPackages = "downloads_and_packages"
    case appCaches = "app_caches"
    case systemCaches = "system_caches"
    case systemLogs = "system_logs"
    case orphanLeftovers = "orphan_leftovers"
    case largeFiles = "large_files"

    public var displayName: String {
        switch self {
        case .messagingMedia: return l10n("通讯软件缓存", "Messaging & Social Media")
        case .developerCaches: return l10n("开发者与模拟器数据", "Developer & Simulator Caches")
        case .browserCaches: return l10n("浏览器缓存", "Browser Caches")
        case .downloadsAndPackages: return l10n("已下载安装包 (DMG/PKG)", "Downloaded Installers (DMG/PKG)")
        case .appCaches: return l10n("应用日常运行缓存", "Application Runtime Caches")
        case .systemCaches: return l10n("系统缓存与快照", "System Caches & Snapshots")
        case .systemLogs: return l10n("系统日志与诊断报告", "System Logs & Crash Reports")
        case .orphanLeftovers: return l10n("已卸载应用残留", "Uninstalled App Leftovers")
        case .largeFiles: return l10n("超大文件与老旧镜像 (>500MB)", "Large Files & Old Images (>500MB)")
        }
    }

    public var icon: String {
        switch self {
        case .messagingMedia: return "💬"
        case .developerCaches: return "🛠️"
        case .browserCaches: return "🌐"
        case .downloadsAndPackages: return "📥"
        case .appCaches: return "📱"
        case .systemCaches: return "⚙️"
        case .systemLogs: return "📝"
        case .orphanLeftovers: return "👻"
        case .largeFiles: return "📦"
        }
    }

    public var description: String {
        switch self {
        case .messagingMedia:
            return l10n(
                "Telegram、WhatsApp、Discord、微信、QQ 等通讯工具的媒体流与图片缓存（聊天文字数据库已自动隔离保护）。",
                "Media stream & photo caches from Telegram, WhatsApp, Discord, WeChat, etc. (Chat databases protected)."
            )
        case .developerCaches:
            return l10n(
                "Xcode 模拟器虚拟机镜像、DerivedData 衍生数据、SwiftPM 依赖包与包管理器缓存。",
                "Xcode simulator runtime images, DerivedData builds, SwiftPM and package manager caches."
            )
        case .browserCaches:
            return l10n(
                "Chrome、Safari、Edge 的 Service Worker、GPU 渲染与静态资源缓存（保留已存密码与书签）。",
                "Service workers, GPU render cache, and static assets from Safari, Chrome, and Edge (passwords & bookmarks safe)."
            )
        case .downloadsAndPackages:
            return l10n(
                "下载目录中已安装完成的 DMG/PKG/ISO 安装镜像与解压遗留包（默认不勾选，需手动确认）。",
                "Completed DMG/PKG/ISO installers and archives in Downloads (unselected by default for safety)."
            )
        case .appCaches:
            return l10n(
                "各类桌面应用程序在日常使用中积累的临时磁盘缓存。",
                "Temporary runtime disk caches accumulated by daily desktop applications."
            )
        case .systemCaches:
            return l10n(
                "APFS 本地快照可清除空间、访达快速预览缩略图、iOS 固件更新包等。",
                "APFS local snapshot purges, QuickLook thumbnails, and cached iOS firmware packages."
            )
        case .systemLogs:
            return l10n(
                "系统运行日志、崩溃转储文件与诊断排错报告。",
                "System runtime logs, core crash dumps, and diagnostics troubleshooting reports."
            )
        case .orphanLeftovers:
            return l10n(
                "已在访达中删除的软件遗留在 ~/Library 中的配置、数据与自启项残留。",
                "Orphaned configuration files, data containers, and launch agents left behind in ~/Library."
            )
        case .largeFiles:
            return l10n(
                "桌面、下载、文档与视频目录中超过 500MB 的大体积文件、虚拟机与镜像包（默认不勾选，需手动确认）。",
                "Files over 500MB in Desktop, Downloads, and Documents (unselected by default for safety)."
            )
        }
    }
}

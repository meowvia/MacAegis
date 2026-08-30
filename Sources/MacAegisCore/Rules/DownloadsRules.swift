import Foundation

public struct DownloadsRules: CleanRuleProtocol {
    public let ruleId = "downloads_and_packages"
    public let displayName = "已下载安装包与压缩镜像"
    public let category = CleanCategory.downloadsAndPackages

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let downloadsPath = FileUtils.expandPath("~/Downloads")

        guard fileManager.fileExists(atPath: downloadsPath) else { return items }

        let packageExtensions: Set<String> = [
            "dmg", "pkg", "iso", "xip", "vmdk", "zip", "tar", "gz", "tgz", "7z", "rar", "bz2", "xz"
        ]
        let brokenDownloadExtensions: Set<String> = [
            "crdownload", "download", "part", "tmp"
        ]

        if let files = try? fileManager.contentsOfDirectory(atPath: downloadsPath) {
            for file in files {
                guard !file.hasPrefix(".") else { continue }
                let ext = (file as NSString).pathExtension.lowercased()
                let fullPath = (downloadsPath as NSString).appendingPathComponent(file)

                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) else { continue }

                let size = FileUtils.calculateSize(atPath: fullPath)

                // 1. DMG / PKG / ISO / ZIP / VMDK Installer Packages & Large Archives (> 5MB)
                if (packageExtensions.contains(ext) || file.lowercased().hasPrefix("install ")) && size > 5_000_000 {
                    let item = CleanItem(
                        name: "安装包或压缩镜像: \(file)",
                        path: fullPath,
                        sizeBytes: size,
                        category: .downloadsAndPackages,
                        safetyLevel: .caution,
                        itemDescription: "存放于下载文件夹中的安装包或压缩文件，若已安装或已解压可安全清理以释放空间。",
                        isSelected: false // Default UNCHECKED for safety!
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
                // 2. Broken / Interrupted Download fragments (> 100KB)
                else if brokenDownloadExtensions.contains(ext) && size > 100_000 {
                    let item = CleanItem(
                        name: "下载中断残留碎片: \(file)",
                        path: fullPath,
                        sizeBytes: size,
                        category: .downloadsAndPackages,
                        safetyLevel: .safe,
                        itemDescription: "历史下载失败或中断遗留的半截临时文件。",
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

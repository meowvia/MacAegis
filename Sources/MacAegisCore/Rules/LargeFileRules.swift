import Foundation

public struct LargeFileRules: CleanRuleProtocol {
    public let ruleId = "large_files_rules"
    public let displayName = "超大文件与老旧镜像 (>500MB)"
    public let category = CleanCategory.largeFiles

    private let minSizeBytes: Int64 = 500_000_000 // 500 MB

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared

        let scanDirs = [
            FileUtils.expandPath("~/Downloads"),
            FileUtils.expandPath("~/Desktop"),
            FileUtils.expandPath("~/Documents"),
            FileUtils.expandPath("~/Movies"),
            FileUtils.expandPath("~/Music")
        ]

        for dir in scanDirs {
            guard fileManager.fileExists(atPath: dir) else { continue }
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: dir),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                guard let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey]),
                      let isDir = res.isDirectory,
                      let isPkg = res.isPackage else { continue }

                // Only inspect non-bundle files or disk images (DMG, ISO, VMDK, MP4, MOV, MKV, ZIP, TAR, etc.)
                if isDir && !isPkg {
                    continue
                }

                let size = Int64(res.fileSize ?? 0)
                guard size >= minSizeBytes else { continue }

                let path = fileURL.path
                if whitelist.isProtected(path: path, mode: .strict) {
                    continue
                }

                let fileName = fileURL.lastPathComponent
                let item = CleanItem(
                    name: "\(fileName) (\(ByteFormatter.format(size)))",
                    path: path,
                    sizeBytes: size,
                    category: .largeFiles,
                    safetyLevel: .caution,
                    itemDescription: "体积超过 500MB 的单体大文件，建议您确认是否仍需保留（默认不勾选）。",
                    isSelected: false
                )
                items.append(item)
                onFoundItem?(item)
            }
        }

        // Sort descending by size
        items.sort { $0.sizeBytes > $1.sizeBytes }
        return items
    }
}

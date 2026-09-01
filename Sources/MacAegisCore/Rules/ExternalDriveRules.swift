import Foundation

public struct ExternalDriveRules: CleanRuleProtocol {
    public let ruleId = "external_drive_rules"
    public let displayName = "外置存储大文件与垃圾残留"
    public let category = CleanCategory.largeFiles

    private let minLargeFileBytes: Int64 = 500_000_000 // 500 MB

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared
        let privacyVault = PrivacyVaultManager.shared

        // 1. Enumerate all mounted external drives
        let mountedDrives = DiskDetector.shared.fetchMountedDrives()
        let externalDrives = mountedDrives.filter { !$0.isInternal }

        for drive in externalDrives {
            let rootPath = drive.mountPath
            guard fileManager.fileExists(atPath: rootPath) else { continue }

            // A. Check External Drive .Trashes
            let trashesPath = (rootPath as NSString).appendingPathComponent(".Trashes")
            if fileManager.fileExists(atPath: trashesPath) && !whitelist.isProtected(path: trashesPath, mode: .strict) && !privacyVault.isLockedForScanSkip(path: trashesPath) {
                let trashSize = FileUtils.calculateSize(atPath: trashesPath)
                if trashSize > 0 {
                    let item = CleanItem(
                        name: "「\(drive.name)」外置废纸篓 (\(ByteFormatter.format(trashSize)))",
                        path: trashesPath,
                        sizeBytes: trashSize,
                        category: .largeFiles,
                        safetyLevel: .caution,
                        itemDescription: "外置硬盘 \(drive.name) 中被删除但未彻底清空的废纸篓空间（默认不勾选）。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }

            // B. Scan for Large Files (>500MB) on External Drive (skipping hidden & system directories)
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: rootPath),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            var scannedFiles = 0
            while let fileURL = enumerator.nextObject() as? URL {
                scannedFiles += 1
                if scannedFiles > 5000 { break } // Bound iteration for responsive UI

                guard let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey]),
                      let isDir = res.isDirectory,
                      let isPkg = res.isPackage else { continue }

                if isDir && !isPkg {
                    // Skip system metadata dirs
                    let name = fileURL.lastPathComponent
                    if name == ".Spotlight-V100" || name == ".fseventsd" || name == ".DocumentRevisions-V100" {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                let size = Int64(res.fileSize ?? 0)
                guard size >= minLargeFileBytes else { continue }

                let path = fileURL.path
                if whitelist.isProtected(path: path, mode: .strict) || privacyVault.isLockedForScanSkip(path: path) {
                    continue
                }

                let lowerPath = path.lowercased()
                let isSensitive = lowerPath.contains("backup") ||
                                  lowerPath.contains("备份") ||
                                  lowerPath.contains("重要") ||
                                  lowerPath.contains("archive") ||
                                  lowerPath.contains("timemachine") ||
                                  lowerPath.contains("photo") ||
                                  lowerPath.contains("相册") ||
                                  lowerPath.contains("document")

                let desc: String
                if isSensitive {
                    desc = "⚠️ 敏感外置数据: 位于外置盘「\(drive.name)」的重要或备份归档大文件（体积 \(ByteFormatter.format(size))，默认不勾选）。"
                } else {
                    desc = "外置硬盘「\(drive.name)」中体积超过 500MB 的单体文件（默认不勾选）。"
                }

                let item = CleanItem(
                    name: "\(fileURL.lastPathComponent) (\(ByteFormatter.format(size)))",
                    path: path,
                    sizeBytes: size,
                    category: .largeFiles,
                    safetyLevel: isSensitive ? .caution : .caution,
                    itemDescription: desc,
                    isSelected: false
                )
                items.append(item)
                onFoundItem?(item)
            }
        }

        items.sort { $0.sizeBytes > $1.sizeBytes }
        return items
    }
}

import Foundation

public struct ExternalDriveRules: CleanRuleProtocol {
    public let ruleId = "external_drive_rules"
    public let displayName = "外置存储大文件与安装包"
    public let category = CleanCategory.largeFiles

    private let minLargeFileBytes: Int64 = 100_000_000 // 100 MB

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

            // A. Check External Drive User Trash (仅探测当前用户有权限清理的子目录)
            let uid = getuid()
            let userTrashPath = ((rootPath as NSString).appendingPathComponent(".Trashes") as NSString).appendingPathComponent("\(uid)")
            if fileManager.fileExists(atPath: userTrashPath) && !whitelist.isProtected(path: userTrashPath, mode: .strict) && !privacyVault.isLockedForScanSkip(path: userTrashPath) {
                let trashSize = FileUtils.calculateSize(atPath: userTrashPath)
                if trashSize > 0 {
                    let item = CleanItem(
                        name: "「\(drive.name)」外置隐藏废纸篓 (\(ByteFormatter.format(trashSize)))",
                        path: userTrashPath,
                        sizeBytes: trashSize,
                        category: .largeFiles,
                        safetyLevel: .caution,
                        itemDescription: "外置硬盘「\(drive.name)」中已被移入废纸篓但未彻底清空的隐藏空间（体积 \(ByteFormatter.format(trashSize))）。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }

            // B. Check Steam External Library Downloading Fragments
            let steamDownloading = (rootPath as NSString).appendingPathComponent("SteamLibrary/steamapps/downloading")
            if fileManager.fileExists(atPath: steamDownloading) && !whitelist.isProtected(path: steamDownloading) && !privacyVault.isLockedForScanSkip(path: steamDownloading) {
                let dlSize = FileUtils.calculateSize(atPath: steamDownloading)
                if dlSize > 100_000_000 { // > 100MB
                    let item = CleanItem(
                        name: "「\(drive.name)」Steam 外置库未完成下载碎片",
                        path: steamDownloading,
                        sizeBytes: dlSize,
                        category: .largeFiles,
                        safetyLevel: .caution,
                        itemDescription: "外置库中断或异常残留的游戏下载分片数据（默认不勾选）。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }

            // C. Scan for External Drive Installers (DMG/PKG/ISO) & Large Files (>100MB)
            if let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: rootPath),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                var scannedCount = 0
                while let fileURL = enumerator.nextObject() as? URL {
                    scannedCount += 1
                    if scannedCount > 50_000 { break }

                    guard let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey]),
                          let isDir = res.isDirectory,
                          let isPkg = res.isPackage else { continue }

                    if isDir && !isPkg {
                        let name = fileURL.lastPathComponent
                        if name == ".Spotlight-V100" || name == ".fseventsd" || name == ".DocumentRevisions-V100" || name == "System Volume Information" || name == ".Trashes" || name == ".git" || name == "node_modules" || name == ".build" {
                            enumerator.skipDescendants()
                        }
                        continue
                    }

                    let size = Int64(res.fileSize ?? 0)
                    let path = fileURL.path
                    if whitelist.isProtected(path: path, mode: .strict) || privacyVault.isLockedForScanSkip(path: path) {
                        continue
                    }

                    let ext = fileURL.pathExtension.lowercased()
                    let isInstaller = ext == "dmg" || ext == "pkg" || ext == "iso" || ext == "xip"

                    // Case 1: Installer Package on External Drive (even if <100MB, e.g. >20MB)
                    if isInstaller && size > 20_000_000 {
                        let item = CleanItem(
                            name: "「\(drive.name)」安装包 \(fileURL.lastPathComponent)",
                            path: path,
                            sizeBytes: size,
                            category: .downloadsAndPackages,
                            safetyLevel: .caution,
                            itemDescription: "存放在外置盘「\(drive.name)」的系统/应用安装镜像（体积 \(ByteFormatter.format(size))，默认不勾选）。",
                            isSelected: false
                        )
                        items.append(item)
                        onFoundItem?(item)
                    } else if size >= minLargeFileBytes {
                        // Case 2: Large File (>100MB) on External Drive
                        let item = CleanItem(
                            name: "「\(drive.name)」\(fileURL.lastPathComponent) (\(ByteFormatter.format(size)))",
                            path: path,
                            sizeBytes: size,
                            category: .largeFiles,
                            safetyLevel: .caution,
                            itemDescription: "外置硬盘「\(drive.name)」中体积超过 100MB 的大文件（默认不勾选，防误删）。",
                            isSelected: false
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }

            // D. Check External Drive Temporary Items & FCP Render Caches (Category: systemCaches)
            let tempItems = (rootPath as NSString).appendingPathComponent(".TemporaryItems")
            if fileManager.fileExists(atPath: tempItems) && !whitelist.isProtected(path: tempItems, mode: .strict) && !privacyVault.isLockedForScanSkip(path: tempItems) {
                let tempSize = FileUtils.calculateSize(atPath: tempItems)
                if tempSize > 1_000_000 {
                    let item = CleanItem(
                        name: "「\(drive.name)」临时交换分区与元数据缓存",
                        path: tempItems,
                        sizeBytes: tempSize,
                        category: .systemCaches,
                        safetyLevel: .safe,
                        itemDescription: "macOS 写入外置盘时产生的系统临时缓存与挂载碎片。",
                        isSelected: true
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }

            if let rootContents = try? fileManager.contentsOfDirectory(atPath: rootPath) {
                for sub in rootContents where sub.hasSuffix(".fcpbundle") {
                    let bundlePath = (rootPath as NSString).appendingPathComponent(sub)
                    let renderPath = (bundlePath as NSString).appendingPathComponent("Render Files")
                    if fileManager.fileExists(atPath: renderPath) && !whitelist.isProtected(path: renderPath) && !privacyVault.isLockedForScanSkip(path: renderPath) {
                        let renderSize = FileUtils.calculateSize(atPath: renderPath)
                        if renderSize > 50_000_000 {
                            let item = CleanItem(
                                name: "「\(drive.name)」FCP 渲染中间件 (\(sub))",
                                path: renderPath,
                                sizeBytes: renderSize,
                                category: .systemCaches,
                                safetyLevel: .safe,
                                itemDescription: "存放在外置盘的 Final Cut Pro 剪辑库历史 ProRes 渲染切片，成片后可安全释放。",
                                isSelected: true
                            )
                            items.append(item)
                            onFoundItem?(item)
                        }
                    }
                }
            }
        }

        items.sort { $0.sizeBytes > $1.sizeBytes }
        return items
    }
}

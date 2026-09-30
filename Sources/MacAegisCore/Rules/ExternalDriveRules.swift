import Foundation

public struct ExternalDriveRules: CleanRuleProtocol {
    public let ruleId = "external_drive_rules"
    public let displayName = "外置存储大文件与安装包"
    public let category = CleanCategory.largeFiles

    private let minLargeFileBytes: Int64 = 100_000_000 // 100 MB

    public init() {}

    private func isNetworkOrVirtualVolume(url: URL, path: String) -> Bool {
        // 1. URL resource key check
        if let vals = try? url.resourceValues(forKeys: [.volumeIsLocalKey, .volumeIsReadOnlyKey]) {
            if vals.volumeIsLocal == false || vals.volumeIsReadOnly == true {
                return true
            }
        }

        // 2. POSIX statfs check
        var stat = statfs()
        if statfs(path, &stat) == 0 {
            if (stat.f_flags & UInt32(MNT_LOCAL)) == 0 || (stat.f_flags & UInt32(MNT_RDONLY)) != 0 {
                return true
            }
            let fsType = withUnsafeBytes(of: &stat.f_fstypename) { raw in
                String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self)).lowercased()
            }
            let remoteFsTypes: Set<String> = ["smbfs", "nfs", "afp", "webdav", "ftp", "cifs"]
            if remoteFsTypes.contains(fsType) {
                return true
            }
        }

        // 3. Virtual / DMG / Installer mount path check
        if path.hasPrefix("/Volumes/MacAegis") || path.hasPrefix("/Volumes/Phantom") {
            return true
        }

        return false
    }

    private func isTimeMachineBackupVolume(path: String) -> Bool {
        if path.contains("/.timemachine/") || path.hasSuffix(".backup") || path.contains("Backups.backupdb") {
            return true
        }
        let fm = FileManager.default
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("backup_manifest.plist")) {
            return true
        }
        return false
    }

    private func isSpotlightIndexed(path: String) -> Bool {
        let spotlightDir = (path as NSString).appendingPathComponent(".Spotlight-V100")
        if FileManager.default.fileExists(atPath: spotlightDir) {
            return true
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        task.arguments = ["-s", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        if let str = String(data: data, encoding: .utf8), str.contains("Indexing enabled") {
            return true
        }
        return false
    }

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
            let rootURL = URL(fileURLWithPath: rootPath)

            // Strict Filter: Never scan remote network shares (smbfs/nfs) or read-only/installer images
            if isNetworkOrVirtualVolume(url: rootURL, path: rootPath) {
                continue
            }

            // Strict Filter: Never scan Time Machine backup snapshots (kernel protected)
            if isTimeMachineBackupVolume(path: rootPath) {
                continue
            }

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

            // C. Scan for External Drive Installers (DMG/PKG/ISO/XIP) & Large Files (>100MB)
            // Use macOS native Spotlight mdfind for 0.05s instant full penetration (zero 50k file ceiling truncation)
            if isSpotlightIndexed(path: rootPath) {
                scanWithSpotlight(
                    rootPath: rootPath,
                    driveName: drive.name,
                    whitelist: whitelist,
                    privacyVault: privacyVault,
                    items: &items,
                    onFoundItem: onFoundItem
                )
            } else {
                scanWithBoundedTraversal(
                    rootPath: rootPath,
                    driveName: drive.name,
                    whitelist: whitelist,
                    privacyVault: privacyVault,
                    items: &items,
                    onFoundItem: onFoundItem
                )
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

    private func scanWithSpotlight(
        rootPath: String,
        driveName: String,
        whitelist: WhitelistManager,
        privacyVault: PrivacyVaultManager,
        items: inout [CleanItem],
        onFoundItem: (@Sendable (CleanItem) -> Void)?
    ) {
        let fileManager = FileManager.default
        let query = "kMDItemFSSize >= 20000000 && (kMDItemFSName == \"*.dmg\" || kMDItemFSName == \"*.pkg\" || kMDItemFSName == \"*.iso\" || kMDItemFSName == \"*.xip\" || kMDItemFSSize >= 100000000)"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = ["-onlyin", rootPath, query]
        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()

            guard task.terminationStatus == 0, let str = String(data: data, encoding: .utf8) else {
                scanWithBoundedTraversal(rootPath: rootPath, driveName: driveName, whitelist: whitelist, privacyVault: privacyVault, items: &items, onFoundItem: onFoundItem)
                return
            }

            let lines = str.split(separator: "\n")
            for line in lines {
                let path = String(line)
                guard !path.isEmpty, fileManager.fileExists(atPath: path) else { continue }
                if whitelist.isProtected(path: path, mode: .strict) || privacyVault.isLockedForScanSkip(path: path) {
                    continue
                }

                let fileURL = URL(fileURLWithPath: path)
                let ext = fileURL.pathExtension.lowercased()
                let isInstaller = ext == "dmg" || ext == "pkg" || ext == "iso" || ext == "xip"
                let size = FileUtils.calculateSize(atPath: path)
                let fileName = fileURL.lastPathComponent

                if isInstaller && size > 20_000_000 {
                    let item = CleanItem(
                        name: "「\(driveName)」安装包 \(fileName)",
                        path: path,
                        sizeBytes: size,
                        category: .downloadsAndPackages,
                        safetyLevel: .caution,
                        itemDescription: "存放在外置盘「\(driveName)」的系统/应用安装镜像（体积 \(ByteFormatter.format(size))，默认不勾选）。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                } else if size >= minLargeFileBytes {
                    let item = CleanItem(
                        name: "「\(driveName)」\(fileName) (\(ByteFormatter.format(size)))",
                        path: path,
                        sizeBytes: size,
                        category: .largeFiles,
                        safetyLevel: .caution,
                        itemDescription: "外置硬盘「\(driveName)」中体积超过 100MB 的大文件（默认不勾选，防误删）。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        } catch {
            scanWithBoundedTraversal(rootPath: rootPath, driveName: driveName, whitelist: whitelist, privacyVault: privacyVault, items: &items, onFoundItem: onFoundItem)
        }
    }

    private func scanWithBoundedTraversal(
        rootPath: String,
        driveName: String,
        whitelist: WhitelistManager,
        privacyVault: PrivacyVaultManager,
        items: inout [CleanItem],
        onFoundItem: (@Sendable (CleanItem) -> Void)?
    ) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: rootPath),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        var count = 0
        while let fileURL = enumerator.nextObject() as? URL {
            count += 1
            if count > 30_000 { break }

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

            if isInstaller && size > 20_000_000 {
                let item = CleanItem(
                    name: "「\(driveName)」安装包 \(fileURL.lastPathComponent)",
                    path: path,
                    sizeBytes: size,
                    category: .downloadsAndPackages,
                    safetyLevel: .caution,
                    itemDescription: "存放在外置盘「\(driveName)」的系统/应用安装镜像（体积 \(ByteFormatter.format(size))，默认不勾选）。",
                    isSelected: false
                )
                items.append(item)
                onFoundItem?(item)
            } else if size >= minLargeFileBytes {
                let item = CleanItem(
                    name: "「\(driveName)」\(fileURL.lastPathComponent) (\(ByteFormatter.format(size)))",
                    path: path,
                    sizeBytes: size,
                    category: .largeFiles,
                    safetyLevel: .caution,
                    itemDescription: "外置硬盘「\(driveName)」中体积超过 100MB 的大文件（默认不勾选，防误删）。",
                    isSelected: false
                )
                items.append(item)
                onFoundItem?(item)
            }
        }
    }
}

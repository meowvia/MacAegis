import Foundation

public struct SystemCacheRules: CleanRuleProtocol {
    public let ruleId = "system_caches_and_logs"
    public let displayName = "系统日志与深层维护缓存"
    public let category = CleanCategory.systemCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared

        // 1. User Logs (~/Library/Logs) & System Logs (/private/var/log)
        let logTargets: [(name: String, path: String, desc: String, category: CleanCategory, safety: SafetyLevel)] = [
            ("用户与应用运行日志", "~/Library/Logs", "应用程序和系统运行中输出的文本日志及历史记录，可随时安全清理", .systemLogs, .safe),
            ("系统底层运行日志与转储", "/private/var/log", "系统底层守护进程生成的轮替日志", .systemLogs, .safe),
            ("系统崩溃与故障诊断报告", "~/Library/DiagnosticReports", "历史程序崩溃转储报告文件，清理后不影响任何软件正常运行", .systemLogs, .safe),
            ("系统诊断流水线与排错数据", "/private/var/db/DiagnosticPipeline", "macOS 自动收集的系统诊断与性能度量中间包", .systemLogs, .safe),
            ("系统全局组件运行缓存", "/Library/Caches", "macOS 系统底层服务与共享组件的临时运行缓存", .systemCaches, .safe),

            // 2. iOS 同步与升级包
            ("iOS 固件恢复与升级包 (IPSW)", "~/Library/iTunes/iPhone Software Updates", "Mac 连接 iPhone/iPad 刷机或系统更新时下载的固件安装包", .systemCaches, .safe),
            ("iOS 跨设备同步临时缓存", "~/Library/Group Containers/group.com.apple.osupdate", "设备固件无线分发与同步传输临时数据", .systemCaches, .safe),

            // 3. 历史窗口恢复镜像
            ("已退出软件历史窗口恢复镜像", "~/Library/Saved Application State", "记录上次退出软件时的窗口位置和标签状态，清理后仅以初始状态打开软件", .systemCaches, .safe)
        ]

        for target in logTargets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 500_000 { // > 500KB
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: target.category,
                        safetyLevel: target.safety,
                        itemDescription: target.desc,
                        isSelected: target.safety == .safe
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        // 4. QuickLook Thumbnail Cache
        let tmpDir = NSTemporaryDirectory()
        let quickLookRoot = (tmpDir as NSString).deletingLastPathComponent
        let possibleQuickLookPaths = [
            quickLookRoot + "/C/com.apple.QuickLook.thumbnailcache",
            FileUtils.expandPath("~/Library/Caches/com.apple.QuickLook.thumbnailcache")
        ]

        for qlPath in possibleQuickLookPaths {
            if fileManager.fileExists(atPath: qlPath) && !whitelist.isProtected(path: qlPath) {
                let size = FileUtils.calculateSize(atPath: qlPath)
                if size > 5_000_000 { // > 5MB
                    let item = CleanItem(
                        name: "访达图片与视频快速预览缓存",
                        path: qlPath,
                        sizeBytes: size,
                        category: .systemCaches,
                        safetyLevel: .safe,
                        itemDescription: "访达空格预览图片/视频时生成的缩略图缓存，系统会按需自动重新生成。"
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }

        // 5. Scan Broken LaunchAgents / LaunchDaemons
        let launchAgentDirs = [
            FileUtils.expandPath("~/Library/LaunchAgents"),
            "/Library/LaunchAgents"
        ]

        for dir in launchAgentDirs {
            if let files = try? fileManager.contentsOfDirectory(atPath: dir) {
                for file in files where file.hasSuffix(".plist") {
                    let plistPath = (dir as NSString).appendingPathComponent(file)
                    // Check if plist target binary exists; if not, it's a broken orphan launcher
                    if isBrokenLaunchAgent(plistPath: plistPath) {
                        let item = CleanItem(
                            name: "失效损坏的开机启动服务: \(file)",
                            path: plistPath,
                            sizeBytes: 4096,
                            category: .systemCaches,
                            safetyLevel: .safe,
                            itemDescription: "已卸载软件残留的失效启动配置文件，清理可提升开机与后台响应速度。"
                        )
                        items.append(item)
                        onFoundItem?(item)
                    }
                }
            }
        }

        // 6. APFS Local Snapshots Detection (tmutil listlocalsnapshots /)
        let tmProcess = Process()
        tmProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        tmProcess.arguments = ["listlocalsnapshots", "/"]
        let pipe = Pipe()
        tmProcess.standardOutput = pipe
        if (try? tmProcess.run()) != nil {
            tmProcess.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                let lines = output.components(separatedBy: .newlines)
                let snapshots = lines.filter { $0.contains("com.apple.TimeMachine") }
                if !snapshots.isEmpty {
                    let estimatedSize: Int64 = Int64(snapshots.count) * 2_500_000_000
                    let snapshotPath = FileUtils.expandPath("~/Library/Caches/com.apple.TimeMachine.Snapshots")
                    let item = CleanItem(
                        name: "APFS 本地快照 (\(snapshots.count) 个)",
                        path: snapshotPath,
                        sizeBytes: estimatedSize,
                        category: .systemCaches,
                        safetyLevel: .caution,
                        itemDescription: "macOS 自动创建的 APFS 本地恢复快照，通过系统 tmutil 平滑释放，不影响外置磁盘备份。",
                        isSelected: false
                    )
                    items.append(item)
                    onFoundItem?(item)
                }
            }
        }
        // Parse system log archives
        let sysLogDir = "/private/var/log"
        if fileManager.fileExists(atPath: sysLogDir) {
            if let files = try? fileManager.contentsOfDirectory(atPath: sysLogDir) {
                for f in files {
                    let p = (sysLogDir as NSString).appendingPathComponent(f)
                    if whitelist.isProtected(path: p) { continue }
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: p, isDirectory: &isDir), !isDir.boolValue {
                        let size = FileUtils.calculateSize(atPath: p)
                        if size > 1_000_000 {
                            let item = CleanItem(
                                name: "系统日志归档: \(f)",
                                path: p, sizeBytes: size,
                                category: .systemLogs, safetyLevel: .safe,
                                itemDescription: "newsyslog 轮替归档的系统日志",
                                isSelected: true)
                            items.append(item)
                            onFoundItem?(item)
                        }
                    }
                }
            }
        }


        return items
    }

    private func isBrokenLaunchAgent(plistPath: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return false
        }

        if let program = dict["Program"] as? String {
            return !FileManager.default.fileExists(atPath: program)
        }
        if let args = dict["ProgramArguments"] as? [String], let first = args.first {
            return !FileManager.default.fileExists(atPath: first)
        }
        return false
    }
}

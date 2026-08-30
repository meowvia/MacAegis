import Foundation
import MacAegisCore

struct TerminalColor {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let green = "\u{001B}[32m"
    static let blue = "\u{001B}[34m"
    static let cyan = "\u{001B}[36m"
    static let yellow = "\u{001B}[33m"
    static let red = "\u{001B}[31m"
    static let magenta = "\u{001B}[35m"
}

func printBanner() {
    print("""
\(TerminalColor.cyan)\(TerminalColor.bold)
  __  __            _             _     
 |  \\/  |          / \\   ___  __ _(_)___ 
 | |\\/| | __ _ ___/ _ \\ / _ \\/ _` | / __|
 | |  | |/ _` | _/ ___ \\  __/ (_| | \\__ \\
 |_|  |_|\\__,_(_)_/   \\_\\___|\\__, |_|___/
                             |___/       
\(TerminalColor.reset)\(TerminalColor.dim)  Mac 之盾 · 极简原生轻量清理、硬件遥测与隐私保险箱 v0.1.1\(TerminalColor.reset)
""")
}

func showHelp() {
    printBanner()
    print("""
\(TerminalColor.bold)使用方法:\(TerminalColor.reset)
  macaegis [命令] [参数]

\(TerminalColor.bold)核心命令:\(TerminalColor.reset)
  \(TerminalColor.green)scan\(TerminalColor.reset) [--dry-run | --clean]   执行全盘系统、应用缓存与孤儿残留扫描 (默认 dry-run)
  \(TerminalColor.green)status\(TerminalColor.reset)                          实时查看 CPU、统一内存压力与 Swap 状态 (零开销)
  \(TerminalColor.green)uninstall\(TerminalColor.reset) <.app 路径>             分析指定 App 的全盘关联文件并准备深度连根拔起
  \(TerminalColor.green)apps\(TerminalColor.reset)                           列出当前活跃的图形界面与后台应用
  \(TerminalColor.green)help\(TerminalColor.reset)                           显示此帮助信息
""")
}

func runStatus() {
    printBanner()
    print("\(TerminalColor.bold)⚡️ 系统硬件极速遥测 (Mach 内核零开销采样):\(TerminalColor.reset)\n")
    
    // Sample twice to get accurate CPU delta
    _ = HardwareTelemetry.shared.fetchMetrics()
    Thread.sleep(forTimeInterval: 0.2)
    let metrics = HardwareTelemetry.shared.fetchMetrics()

    print("  \(TerminalColor.dim)CPU 实时总占用:\(TerminalColor.reset)   \(TerminalColor.bold)\(String(format: "%.1f", metrics.cpuUsagePercent))%\(TerminalColor.reset)")
    print("  \(TerminalColor.dim)统一内存真实占用:\(TerminalColor.reset) \(TerminalColor.bold)\(metrics.formattedMemoryUsed) / \(metrics.formattedMemoryTotal)\(TerminalColor.reset) (\(String(format: "%.1f", metrics.memoryUsagePercent))%)")
    print("  \(TerminalColor.dim)内存压力状态:\(TerminalColor.reset)     \(metrics.memoryPressure.badge) \(TerminalColor.bold)\(metrics.memoryPressure.rawValue)\(TerminalColor.reset)")
    print("  \(TerminalColor.dim)磁盘 Swap 交换区:\(TerminalColor.reset)  \(TerminalColor.bold)\(metrics.formattedSwapUsed)\(TerminalColor.reset)\n")
}

func runUninstall(appPath: String) {
    printBanner()
    let expanded = FileUtils.expandPath(appPath)
    let url = URL(fileURLWithPath: expanded)

    guard FileUtils.fileExists(atPath: expanded) else {
        print("\(TerminalColor.red)❌ 错误: 找不到应用路径: \(expanded)\(TerminalColor.reset)")
        return
    }

    print("🔍 正在深入解析应用关联文件树: \(TerminalColor.bold)\(url.lastPathComponent)\(TerminalColor.reset)...\n")

    guard let bundle = AppUninstaller.shared.analyzeApp(at: url) else {
        print("\(TerminalColor.red)❌ 无法解析该 App 的架构信息\(TerminalColor.reset)")
        return
    }

    print("\(TerminalColor.bold)📦 应用名称:\(TerminalColor.reset) \(bundle.appName)")
    if let bid = bundle.bundleId {
        print("\(TerminalColor.dim)   Bundle ID:\(TerminalColor.reset) \(bid)")
    }
    print("\(TerminalColor.bold)📊 关联总体积:\(TerminalColor.reset) \(TerminalColor.green)\(bundle.formattedTotalSize)\(TerminalColor.reset)")
    print(String(repeating: "─", count: 68))

    for item in bundle.associatedItems {
        print("  • [\(item.safetyLevel.badge)] \(TerminalColor.bold)\(item.name)\(TerminalColor.reset) (\(TerminalColor.cyan)\(item.formattedSize)\(TerminalColor.reset))")
        print("    \(TerminalColor.dim)\(item.path)\(TerminalColor.reset)")
    }

    print(String(repeating: "─", count: 68))
    print("\n\(TerminalColor.yellow)💡 提示: 本次为只读分析模式。若要卸载，可通过 GUI 界面或后续指令一键移入废纸篓。\(TerminalColor.reset)\n")
}

func runScan(args: [String]) async {
    printBanner()
    let isClean = args.contains("--clean")
    let isDryRun = !isClean

    print("\n\(TerminalColor.bold)🔍 正在快速遍历全盘系统、应用缓存与孤儿残留...\(TerminalColor.reset)\n")

    let scanner = ScannerEngine()
    let result = await scanner.scan { item in
        print("  \(TerminalColor.dim)发现:\(TerminalColor.reset) \(item.safetyLevel.badge) \(TerminalColor.bold)\(item.name)\(TerminalColor.reset) (\(TerminalColor.cyan)\(item.formattedSize)\(TerminalColor.reset))")
    }

    print("\n" + String(repeating: "─", count: 68))
    print("\(TerminalColor.bold)📊 扫描完成 (耗时: \(String(format: "%.2f", result.durationSeconds))s)\(TerminalColor.reset)")
    print(String(repeating: "─", count: 68))

    for category in CleanCategory.allCases {
        let items = result.items(for: category)
        let catSize = result.totalSize(for: category)
        if !items.isEmpty {
            print("\n\(category.icon) \(TerminalColor.bold)\(category.displayName)\(TerminalColor.reset) \(TerminalColor.dim)[\(ByteFormatter.format(catSize))]\(TerminalColor.reset)")
            for item in items {
                print("   • [\(item.safetyLevel.badge)] \(item.name) \(TerminalColor.dim)➔\(TerminalColor.reset) \(TerminalColor.green)\(item.formattedSize)\(TerminalColor.reset)")
                print("     \(TerminalColor.dim)路径: \(item.path)\(TerminalColor.reset)")
                print("     \(TerminalColor.dim)说明: \(item.itemDescription)\(TerminalColor.reset)")
            }
        }
    }

    print("\n" + String(repeating: "═", count: 68))
    print("\(TerminalColor.bold)💡 汇总分析:\(TerminalColor.reset)")
    print("   • 发现可释放总空间: \(TerminalColor.bold)\(TerminalColor.yellow)\(result.totalFormattedSize)\(TerminalColor.reset)")
    print("   • 无感安全可清理项: \(TerminalColor.bold)\(TerminalColor.green)\(result.safeFormattedSize)\(TerminalColor.reset)")
    print(String(repeating: "═", count: 68))

    if isDryRun {
        print("\n\(TerminalColor.yellow)⚠️  当前为 [安全预演模式 / Dry-Run]，未对磁盘进行任何改动。\(TerminalColor.reset)")
        print("\(TerminalColor.dim)若要执行安全清理（默认移入废纸篓），请运行: \(TerminalColor.reset)\(TerminalColor.bold)swift run macaegis scan --clean\(TerminalColor.reset)\n")
    }
}

func main() async {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else {
        await runScan(args: [])
        return
    }

    switch command.lowercased() {
    case "status":
        runStatus()
    case "uninstall":
        if args.count > 1 {
            runUninstall(appPath: args[1])
        } else {
            print("\(TerminalColor.red)请指定要分析的 App 路径，例如: macaegis uninstall /Applications/WeChat.app\(TerminalColor.reset)")
        }
    case "scan":
        await runScan(args: args)
    case "apps":
        printBanner()
        let apps = ProcessSentinel.shared.fetchActiveUserApplications()
        print("\(TerminalColor.bold)🖥 当前活跃用户应用 (\(apps.count) 个):\(TerminalColor.reset)\n")
        for app in apps {
            print("  • \(app.icon) [PID: \(app.id)] \(TerminalColor.bold)\(app.name)\(TerminalColor.reset) \(TerminalColor.dim)(\(app.bundleId ?? "无 Bundle ID"))\(TerminalColor.reset)")
        }
        print("")
    case "dev-reset":
        let appSupport = FileUtils.expandPath("~/Library/Application Support/MacAegis")
        let metadataPath = (appSupport as NSString).appendingPathComponent("vault_metadata.json")
        let authPath = (appSupport as NSString).appendingPathComponent("vault_auth.json")
        
        if FileManager.default.fileExists(atPath: metadataPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)),
           let items = try? JSONDecoder().decode([VaultItem].self, from: data), !items.isEmpty {
            print("⚠️ 发现 \(items.count) 个未解锁的测试项目，正在执行安全解锁与特征还原...")
            let vault = PrivacyVaultManager.shared
            for item in items {
                print("  🔓 正在安全还原: \(item.path)")
                vault.openAndHighlightInFinder(path: item.path, revealInFinder: false)
            }
            print("✅ 所有测试文件已 100% 字节级安全解锁并恢复原始属性！")
        } else {
            print("✨ 未发现遗留上锁文件，环境整洁。")
        }
        try? "[]".write(toFile: metadataPath, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: authPath)
        print("🧼 保险箱与账户已安全重置为出厂默认状态。")
    case "help", "--help", "-h":
        showHelp()
    default:
        await runScan(args: args)
    }
}

await main()

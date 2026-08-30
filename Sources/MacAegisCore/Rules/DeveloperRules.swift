import Foundation

public struct DeveloperRules: CleanRuleProtocol {
    public let ruleId = "developer_caches"
    public let displayName = "开发者与模拟器重器"
    public let category = CleanCategory.developerCaches

    public init() {}

    public func scan(onFoundItem: (@Sendable (CleanItem) -> Void)?) async -> [CleanItem] {
        var items: [CleanItem] = []
        let fileManager = FileManager.default
        let whitelist = WhitelistManager.shared

        let devTargets: [(name: String, path: String, desc: String, appName: String, safety: SafetyLevel)] = [
            // 1. Xcode 巨兽级模拟器系统镜像与缓存 (30GB+)
            ("Xcode 模拟器系统镜像 (Simulator Volumes)", "/Library/Developer/CoreSimulator/Volumes", "Xcode 历史下载的 visionOS/watchOS/tvOS 虚拟机系统盘镜像，可释放数十 GB", "Xcode", .safe),
            ("Xcode 模拟器运行时下载缓存 (Simulator Caches)", "/Library/Developer/CoreSimulator/Caches", "Xcode 下载模拟器时保留的解压中间缓存包", "Xcode", .safe),
            ("Xcode 废弃模拟器设备数据 (Simulator Devices)", "~/Library/Developer/CoreSimulator/Devices", "历史测试模拟器中安装的临时沙盒数据，可随时安全清理", "Xcode", .safe),

            // 2. Xcode 衍生构建与编译索引
            ("Xcode 编译衍生数据 (DerivedData)", "~/Library/Developer/Xcode/DerivedData", "Xcode 项目构建和代码索引产生的衍生中间文件，删除后可在下次构建时自动重新生成", "Xcode", .safe),
            ("Xcode 模块与索引缓存", "~/Library/Caches/com.apple.dt.Xcode", "Xcode 内部代码高亮、编译诊断与自动补全索引缓存", "Xcode", .safe),
            ("Xcode 旧版真机调试符号 (iOS DeviceSupport)", "~/Library/Developer/Xcode/iOS DeviceSupport", "连接旧款真机测试时下载的符号缓存，可随时安全清理", "Xcode", .safe),

            // 3. 包管理器与现代构建缓存
            ("SwiftPM 依赖包构建缓存", "~/Library/Caches/org.swift.swiftpm", "Swift Package Manager 下载并解析的远程仓库包缓存", "Xcode", .safe),
            ("Homebrew 安装包下载缓存", "~/Library/Caches/Homebrew", "brew install 下载的软件包压缩包，安装完毕后无需保留", "Homebrew", .safe),
            ("CocoaPods 第三方库源码缓存", "~/Library/Caches/CocoaPods", "CocoaPods 下载的开源库压缩包缓存", "CocoaPods", .safe),
            ("Pip Python 包下载缓存", "~/Library/Caches/pip", "pip 安装 Python 包时保留的 wheel/tar 缓存压缩包", "Python", .safe),
            ("Rust Cargo 下载缓存", "~/.cargo/registry/cache", "Cargo 下载的 crates 包缓存压缩包", "Rust", .safe)
        ]

        for target in devTargets {
            let fullPath = FileUtils.expandPath(target.path)
            if fileManager.fileExists(atPath: fullPath) && !whitelist.isProtected(path: fullPath) {
                let size = FileUtils.calculateSize(atPath: fullPath)
                if size > 5_000_000 { // > 5MB
                    let item = CleanItem(
                        name: target.name,
                        path: fullPath,
                        sizeBytes: size,
                        category: .developerCaches,
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

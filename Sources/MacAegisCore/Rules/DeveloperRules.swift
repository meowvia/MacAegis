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
            ("Xcode 历史应用打包归档 (Archives)", "~/Library/Developer/Xcode/Archives", "历史打包发布的 App 归档包 (可能占用数 GB 至数十 GB)", "Xcode", .caution),
            ("Xcode 编译产物包 (Products)", "~/Library/Developer/Xcode/Products", "历史编译生成的 App 与 Framework 调试产物", "Xcode", .safe),
            ("Xcode 真机日志 (iOS Device Logs)", "~/Library/Developer/Xcode/iOS Device Logs", "连接真机测试时收集的历史崩溃日志与调试转储", "Xcode", .safe),
            ("Xcode 模块与索引缓存", "~/Library/Caches/com.apple.dt.Xcode", "Xcode 内部代码高亮、编译诊断与自动补全索引缓存", "Xcode", .safe),
            ("Xcode 旧版真机调试符号 (iOS DeviceSupport)", "~/Library/Developer/Xcode/iOS DeviceSupport", "连接旧款真机测试时下载的符号缓存，可随时安全清理", "Xcode", .safe),

            // 3. 包管理器与现代构建缓存
            ("SwiftPM 依赖包构建缓存", "~/Library/Caches/org.swift.swiftpm", "Swift Package Manager 下载并解析的远程仓库包缓存", "Xcode", .safe),
            ("Homebrew 安装包下载缓存", "~/Library/Caches/Homebrew", "brew install 下载的软件包压缩包，安装完毕后无需保留", "Homebrew", .safe),
            ("CocoaPods 第三方库源码缓存", "~/Library/Caches/CocoaPods", "CocoaPods 下载的开源库压缩包缓存", "CocoaPods", .safe),
            ("Pip Python 包下载缓存", "~/Library/Caches/pip", "pip 安装 Python 包时保留的 wheel/tar 缓存压缩包", "Python", .safe),
            ("Rust Cargo 下载缓存", "~/.cargo/registry/cache", "Cargo 下载的 crates 包缓存压缩包", "Rust", .safe),

            // 4. Advanced mac-cleanup-py Imported Paths (Node, Gradle, Docker, VSCode, Android)
            ("NPM 全局依赖缓存", "~/.npm/_cacache", "Node.js npm install 产生的下载缓存", "Node.js", .safe),
            ("Yarn 全局依赖缓存", "~/.yarn/cache", "Yarn 包管理器的缓存包", "Yarn", .safe),
            ("Yarn v2 全局缓存", "~/.yarn/berry/cache", "Yarn v2 (Berry) 的缓存数据", "Yarn", .safe),
            ("Gradle 构建与下载缓存", "~/.gradle/caches", "Android/Java 项目使用的 Gradle 依赖包缓存，占用通常达数 GB", "Gradle", .safe),
            ("Maven 本地仓库包缓存", "~/.m2/repository", "Java 开发中下载的各类 Jar 包与依赖，可随时重新下载", "Maven", .safe),
            ("Flutter Pub 依赖包缓存", "~/.pub-cache", "Flutter 开发下载的 Dart 第三方包及构建缓存", "Flutter", .safe),
            ("Composer PHP 依赖缓存", "~/.composer/cache", "PHP Composer 包管理器下载的源码与 Zip 压缩包", "Composer", .safe),
            ("Ruby Gems 依赖缓存", "~/.gem/cache", "Ruby 开发环境下缓存的 gems 包", "Ruby", .safe),
            ("VSCode 软件更新与内部缓存", "~/Library/Application Support/Code/Cache", "Visual Studio Code 内部组件更新及运行时渲染缓存", "VSCode", .safe),
            ("VSCode 扩展下载缓存", "~/Library/Application Support/Code/CachedData", "VSCode 插件市场下载与运行过程中的临时数据包", "VSCode", .safe),
            ("Docker Desktop 容器缓存", "~/Library/Caches/com.docker.docker", "Docker 桌面端运行时产生的中间件缓存", "Docker", .safe),
            ("Android Studio 历史无用日志", "~/Library/Logs/Google", "Android Studio 各种历史版本遗留的日志数据", "Android Studio", .safe)
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

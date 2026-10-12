# 贡献指南 (Contributing Guide)

感谢关注并参与 MacAegis 开源生态建设。MacAegis 的开源核心目标是建立一个透明、纯净且绝无误删风险的 macOS 应用垃圾清理与卸载规则库。

---

## 行为准则与安全红线

任何规则相关的 Pull Request (PR) 必须严格遵守以下安全红线：

1. 零私人数据侵犯：严禁添加任何包含用户文档、照片、桌面文件、聊天数据库（如 `.db`, `.sqlite`）、钥匙串凭证或配置备份的路径；
2. 零破坏性清理：仅允许纳管可由应用安全再生的临时缓存（Caches）、日志（Logs）、下载临时包（Partial Downloads）；
3. 严格安全级别分类 (`SafetyLevel`)：
   - `.safe`：无风险安全清除（如过期日志、浏览器网页缓存）；
   - `.caution`：需用户知情（如大型历史下载、旧模拟器固件）；
   - `.danger`：可能需要重新登录或重新索引的持久缓存。
4. 绝对禁止硬编码绝对用户名：路径必须使用 `FileManager.default.homeDirectoryForCurrentUser` 或 `~/` 相对展开，严禁硬编码 `/Users/xxx`。

---

## 规则编写规范与示例

所有清理规则均位于 `Sources/MacAegisCore/Rules/`，必须遵循 `CleanRuleProtocol`：

```swift
public protocol CleanRuleProtocol: Sendable {
    var id: String { get }
    var category: CleanCategory { get }
    func scan() async throws -> [CleanItem]
}
```

### 规则实现示范模板：

```swift
import Foundation

public struct MyCoolAppRules: CleanRuleProtocol {
    public let id = "my_cool_app_cache"
    public let category = CleanCategory.appCaches

    public init() {}

    public func scan() async throws -> [CleanItem] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let targetURL = home.appendingPathComponent("Library/Caches/com.example.MyCoolApp")

        guard fileManager.fileExists(atPath: targetURL.path) else {
            return []
        }

        let allocatedSize = try? FileUtils.allocatedSize(of: targetURL)

        return [
            CleanItem(
                name: "MyCoolApp 缓存",
                path: targetURL.path,
                size: allocatedSize ?? 0,
                safetyLevel: .safe,
                category: category,
                description: "存储网页渲染与临时图片缓存，清理后不影响账号登录状态。"
            )
        ]
    }
}
```

---

## 提交流程与测试验证

1. Fork 本仓库并新建特性分支：`git checkout -b rule/my-cool-app`；
2. 在 `Tests/MacAegisTests/` 中添加对应的单元测试用例，验证扫描隔离性；
3. 运行全量测试套件并确保 100% 通过：
   ```bash
   swift test
   ```
4. 提交清晰的 Git Commit，并在 PR 描述中附带清理路径与应用官网说明。

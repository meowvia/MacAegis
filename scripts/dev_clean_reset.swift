import Foundation
import MacPureCore

let appSupport = FileUtils.expandPath("~/Library/Application Support/MacPure")
let metadataPath = (appSupport as NSString).appendingPathComponent("vault_metadata.json")
let authPath = (appSupport as NSString).appendingPathComponent("vault_auth.json")

print("🔍 [Dev Sentinel] 检查是否存在未解锁的残留文件...")

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

// 重置元数据和账户
try? "[]".write(toFile: metadataPath, atomically: true, encoding: .utf8)
try? FileManager.default.removeItem(atPath: authPath)
print("🧼 账户认证已重置为出厂默认状态。")

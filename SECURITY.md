# 安全与隐私策略 (Security & Privacy Policy)

## 🛡️ 核心隐私原则 (Privacy Commitments)

1. **100% 本地离线运行**：MacAegis 不包含任何数据上传代码，不连接任何远程服务器，不收集任何用户隐私或使用习惯数据。
2. **零文件内容改写**：隐私隐匿功能仅修改 macOS 原生文件系统标记与系统级 POSIX 权限（`chmod 000` + `chflags`），绝不破坏原文件结构与二进制内容。
3. **硬件级密钥保护**：主密码通过 PBKDF2 (100,000 次哈希迭代) 派生，密钥存储严格依托于 macOS 原生 Secure Enclave / Apple Keychain。

## 🐛 安全漏洞报告 (Reporting a Vulnerability)

如果您在 MacAegis 中发现了任何安全漏洞或隐患，请通过以下方式联系我们：
* 在 GitHub 提交带有 `[Security]` 前缀的 Private Issue。
* 我们将在 48 小时内确认并评估报告，并优先发布修复版本。

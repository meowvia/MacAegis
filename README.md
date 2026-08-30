# MacAegis

> 专为 macOS 打造的极简、轻量级私密资产保险箱与系统工作台。

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.1.1--Beta-emerald?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Binary%20Size-3.5MB-purple?style=flat-square" alt="Binary Size">
</p>

---

## 🎯 为什么需要 MacAegis？解决哪些真实痛点？

在日常办公、外接显示器、开会投屏或外借电脑时，Mac 用户常常面临各种尴尬与顾虑：

| 用户真实痛点 | 常见场景与后果 | MacAegis 的解决方案 |
| :--- | :--- | :--- |
| **私密文件意外曝光** | 商业合同、财务报表、个人照片或私密资料在投屏或他人查看电脑时，容易通过访达或“最近使用”被瞥见。 | **秒级隐形保险箱**：拖入即可使文件/文件夹彻底隐蔽，访达与快速预览均无法解析或打开，瞬间告别被窥风险。 |
| **传统加密工具太慢且易损坏** | 传统加密软件往往需要漫长的复制写入时间，大文件移动极慢，且一旦加密中断容易导致文件彻底损坏。 | **零等待原地隐匿**：无论 100MB 还是 100GB，无需等待大文件复制，毫秒级完成隐匿与无损还原。 |
| **误删应用导致资产丢失** | 使用隐藏工具后若不慎卸载了 App，常常导致被隐藏的文件无法找回、永久失联。 | **自愈恢复能力**：依托系统级钥匙串凭证托管，即使用户误删了 App，重新安装后依然能自动识别账户，无损解锁原文件。 |
| **网络链路状态不清晰** | 不清楚当前网络流量到底走的是直连、分流还是全局代理，排查连接问题耗时费力。 | **实时网速与代理状态透视**：顶栏与控制台实时展示当前链路（普通直连 / 规则分流 / 全局代理）与实时网速。 |
| **系统垃圾与应用卸载残留** | 长期使用后磁盘充斥着开发缓存、失效日志以及已卸载 App 遗留的深层配置。 | **轻量辅助清理与卸载**：提供按需扫描与深度卸载，剥离残留文件，保持系统清爽。 |

---

## 💎 核心功能介绍

### 1. 🛡️ 核心聚焦：隐私保险箱 (Privacy Vault)
* **拖拽即隐形**：直接将私密文件或文件夹拖入保险箱，瞬间完成隐蔽，访达中不再可见，阻断空格键快速预览。
* **生物识别解锁**：深度集成 Touch ID 指纹识别与主密码验证，一触即开，解锁后自动在访达中定位。
* **零复制、零等待**：采用原地处理机制，无需耗费磁盘双倍空间与长时间写入，大体积视频与工程文件秒级上锁。
* **防误删自愈架构**：即使不小心卸载了 MacAegis，重新安装后依然可无缝认领并还原历史资产。

### 2. 🌐 实时网络与链路透视 (Network & Traffic Telemetry)
* **系统原生层动态探测（不依赖任何特定代理客户端）**：直接从 macOS 系统底层网络动态状态读取，无论你使用的是 v2rayN、Clash、Surge、Shadowrocket 还是系统原生网络设置，均可秒级精准反映电脑真实的流量走向与出海状态。
* **实时上下行速率**：状态栏常驻轻量指示器，实时感知当前网络动态。
* **三色代理链路状态指示**：
  * 🔵 **普通直连**：系统直接连接外网。
  * 🟢 **规则分流**：分流规则生效中。
  * 🔴 **全局代理**：全局网络代理状态。

### 3. 🧹 辅助功能：轻量清理与卸载 (Clean & Uninstaller)
* **缓存与残留清理**：按需清理系统日志、开发构建缓存（Xcode DerivedData 等）与废弃临时文件。
* **关联文件卸载**：拖拽应用快速索引并清理 `~/Library` 中的深层孤儿残留配置。
* **原生轻量设计**：纯 Swift 6 原生构建，安装包仅 **3.5MB**，事件驱动设计，极低系统资源占用。

---

## 💻 系统要求

* **系统版本**：macOS 14.0 (Sonoma) 及以上
* **硬件平台**：Apple Silicon (M 系列芯片) 及 Intel 架构 Mac
* **开发语言**：Swift 6 / SwiftUI (原生 AppKit 混合架构)

---

## 📄 项目主页与反馈

* 官方仓库：[https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)
* 遵循 [MIT 许可证](LICENSE) 发布。

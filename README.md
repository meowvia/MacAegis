# MacAegis (Mac 之盾)

> 专为 macOS 打造的极简、轻量级原生系统清理、硬件监测与隐私守护工作台。

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.1.1--Beta-emerald?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Memory%20Footprint-~28MB-brightgreen?style=flat-square" alt="Memory Footprint">
  <img src="https://img.shields.io/badge/Binary%20Size-3.5MB-purple?style=flat-square" alt="Binary Size">
</p>

---

## 🎯 我们致力于解决哪些真实痛点？

很多 Mac 用户在日常使用中常面临以下困扰：

| 用户真实痛点 | 常见现象与后果 | MacAegis 的解决方案 |
| :--- | :--- | :--- |
| **工具自身臃肿** | 市面上主流清理工具动辄 100MB+ 体积，常驻内存高达 200MB~500MB，后台长期挂载守护进程消耗电量。 | **纯原生极致轻量**：仅 **3.5MB** 单二进制体积，常驻内存仅 **~28MB**，待机 CPU **0.0%**，无任何常驻后台 Daemon。 |
| **残留清理不彻底** | 把 App 拖入废纸篓只删除了主程序，`~/Library` 下的大量缓存、配置和支持文件长期堆积占用几十 GB 空间。 | **全链路深度卸载**：智能分析 App 全盘关联文件，拖拽即卸；遇到被占用的卡死进程自动处理，一键连根拔起。 |
| **误删重要数据风险** | 粗暴的清理工具容易误删未卸载应用的配置，或者误清理关键数据。 | **严格安全核查与预览**：与系统应用注册表交叉校验，非标准路径 App 配置自动保护；清理前支持全维度明细下钻与安全预览。 |
| **敏感资产意外曝光** | 开会投屏、借用电脑或日常办公时，敏感文档、工程文件或私人资料容易在访达预览中被瞥见。 | **毫秒级隐私保险箱**：拖入即刻隐形防护，阻断访达预览与直接打开；集成 Touch ID 瞬间解锁；具备完备的灾难自愈能力。 |
| **网络状态缺乏感知** | 不清楚当前应用流量究竟是直连还是走了代理分流，经常造成流量浪费或连接异常。 | **实时网速与代理状态透视**：顶栏与控制台实时显示实时上传/下载速率，并清晰标识当前链路（直连 / 规则分流 / 全局代理）。 |

---

## 📦 核心功能板块

### 1. 智能清理 (Smart Clean)
* **系统与应用缓存**：安全扫描 Xcode DerivedData、开发构建缓存、应用日志与浏览器临时数据。
* **大文件与安装包**：快速定位磁盘中被遗忘的 `.dmg`、`.pkg` 与大体积归档文件。
* **孤儿残留识别**：精准扫描已卸载应用遗留在系统中的废弃目录。
* **安全白名单机制**：对系统核心组件、钥匙串与关键数据库实行默认保护，杜绝误操作。

### 2. 深度卸载器 (Smart Uninstaller)
* **拖拽即卸**：直接将应用程序拖入窗口即可自动检索其在 `Application Support`、`Caches`、`Containers` 中的所有关联文件。
* **全盘应用索引**：可视化列出所有已安装软件，按体积与最后修改时间清晰排序。

### 3. 系统遥测与网络状态 (System Telemetry & Network Monitor)
* **硬件健康监测**：零开销读取 CPU 实时负载、统一内存真实压力、Swap 交换区与 SoC 芯片温度。
* **流量与代理链路指示**：
  * 🔵 **普通直连**：系统直通外网，无代理接管。
  * 🟢 **规则分流**：智能分流链路生效中。
  * 🔴 **全局代理**：所有流量接管状态。

### 4. 隐私保险箱 (Privacy Vault)
* **文件秒级隐蔽防护**：将私密文件或文件夹拖入即可完成保护，无需等待大文件复制。
* **生物识别支持**：支持 Touch ID 指纹一键解锁与本地主密码门禁。
* **防误删自愈架构**：即使不慎卸载应用，重新安装后即可直接认领原有账户并无损还原受保护资产。

---

## 💻 系统要求

* **操作系统**：macOS 14.0 (Sonoma) 或更高版本
* **硬件平台**：Apple Silicon (M1 / M2 / M3 / M4 系列) 及 Intel 架构 Mac
* **开发语言**：Swift 6 / SwiftUI (原生 AppKit 混合深度集成)

---

## 📄 参与与反馈

如果你在测试使用中遇到任何问题或有改进建议，欢迎通过 GitHub Issues 提交反馈：
* 官方仓库：[https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)

MacAegis 遵循 [MIT 许可证](LICENSE) 发布。

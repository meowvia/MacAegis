# MacAegis

> 专为 macOS 打造的系统网络透视、私密资产保险箱与轻量工作台。

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.1.1--Beta-emerald?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Memory%20Footprint-~28MB-brightgreen?style=flat-square" alt="Memory Footprint">
  <img src="https://img.shields.io/badge/Binary%20Size-3.5MB-purple?style=flat-square" alt="Binary Size">
</p>

---

## 🎯 解决哪些真实痛点？

在日常办公、投屏演示、科学上网或多任务开发时，Mac 用户常面临以下困扰：

| 用户真实痛点 | 常见困境与后果 | MacAegis 解决方案 |
| :--- | :--- | :--- |
| **网络链路缺乏感知** | 搞不清当前网络到底是直连、分流还是全局代理，排查连接异常或流量消耗耗时费力。 | **系统层动态透视**：直读系统底层网络状态，不依赖任何特定代理客户端；顶栏实时展示上传/下载速率与三色分流状态。 |
| **敏感资产意外被窥** | 投屏开会、借用电脑时，商业合同、财务报表、私人照片容易在访达（Finder）或“最近使用”中被旁人瞥见。 | **秒级隐形保险箱**：拖入即刻隐形，访达中不再可见，空格键快速预览无法解析；支持 Touch ID 瞬间解锁。 |
| **传统加密缓慢脆弱** | 传统加密工具动辄复制几十 GB 大文件，耗时长且耗费双倍磁盘空间；加密中断还存在文件损坏风险。 | **零复制原地隐匿**：无论 100MB 还是 100GB，无需等待大文件复制，毫秒级完成原地隐形与无损还原。 |
| **清理工具自身臃肿** | 主流清理工具体积 100MB+，常驻内存高达 200MB~500MB，后台长期挂载守护进程消耗电量。 | **纯原生极致轻量**：仅 **3.5MB** 单二进制体积，常驻内存仅 **~28MB**，待机 CPU **< 0.1%**，无后台常驻 Daemon。 |
| **卸载残留深埋系统** | 把 App 拖入废纸篓只删除了主程序，`~/Library` 下累积大量孤儿配置与缓存文件。 | **深度关联卸载**：拖拽应用自动索引并剥离所有支持目录与残留配置，保持系统清爽。 |

---

## 💎 核心功能矩阵

### 1. 🌐 流量与代理透视 (Network & Traffic Telemetry)
* **读取系统层，不依赖任何代理客户端**：直接从 macOS 系统原生网络底层读取真实链路状态，无论是 v2rayN、Clash、Surge、Shadowrocket 还是系统网络设置，均能精准反映出海与分流状态。
* **三色链路状态指示器**：
  * 🔵 **普通直连 (Direct)**：流量直通外网，无代理接管。
  * 🟢 **规则分流 (Rule Routing)**：智能分流规则生效中。
  * 🔴 **全局代理 (Global Proxy)**：全局网络代理接管状态。
* **实时上下行速率**：状态栏与主控台毫秒级采样，实时感知网络吞吐。

### 2. 🛡️ 隐私资产保险箱 (Privacy Vault)
* **拖拽即隐形**：直接将私密文件或文件夹拖入保险箱，瞬间完成隐蔽防护，阻断访达列表展示与快速预览。
* **生物识别与安全门禁**：深度集成 Touch ID 指纹识别与主密码校验，解锁后自动在访达中定位实体。
* **零复制、零等待**：原地即时处理，不进行大文件读写搬运，即便是几十 GB 的工程项目也能毫秒级锁定与释放。
* **自愈恢复设计**：凭证依托 macOS 系统级钥匙串安全托管，即使不慎卸载重装 App，依然能自动认领并无损解锁历史资产。

### 3. 🧹 智能清理 (Smart Clean)
* **按需深度扫描**：清理开发构建缓存（Xcode DerivedData、Cargo 等）、应用日常日志与浏览器临时缓存。
* **大文件与安装包定位**：快速检索被遗忘的 `.dmg`、`.pkg` 及超大冗余文件。
* **安全白名单拦截**：对系统核心组件、钥匙串与关键数据实行默认保护，杜绝误操作。

### 4. 🗑️ 深度卸载器 (Smart Uninstaller)
* **全关联文件检索**：拖拽应用程序即可自动定位其在 `Application Support`、`Caches`、`Containers` 中的全部深层残留。
* **卡死进程自动处理**：遇到被占用的后台残留进程自动安全回收，一键连根清理。

---

## 💻 系统要求

* **系统版本**：macOS 14.0 (Sonoma) 及以上
* **硬件平台**：Apple Silicon (M 系列芯片) 及 Intel 架构 Mac
* **开发语言**：Swift 6 / SwiftUI (原生 AppKit 深度集成)

---

## 📄 项目主页与反馈

* 官方仓库：[https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)
* 遵循 [MIT 许可证](LICENSE) 发布。

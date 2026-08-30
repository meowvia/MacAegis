# MacAegis · 纯原生轻量级 macOS 系统管家与隐私保险箱

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Memory%20Footprint-<%2040MB-brightgreen?style=flat-square" alt="Memory Footprint">
  <img src="https://img.shields.io/badge/License-MIT-purple?style=flat-square" alt="License">
</p>

---

## 🌟 为什么选择 MacAegis？

市面上多数 Mac 清理与监控工具要么基于 Electron 臃肿卡顿、动辄占用数百 MB 内存，要么充斥着复杂的广告弹窗与过度扫描。**MacAegis** 专为追求极致性能与设计美感的 Mac 用户打造：**100% 纯原生 Swift / SwiftUI 开发，零常驻系统负担，秒级深度清理，融合精准网络流量识别与硬件级隐私保险箱。**

---

## 💎 四大核心杀手级特性

### 1. ⚡ 100% 纯原生与极致轻量 (Pure Native & Lightweight)
* **拒绝 Electron 臃肿**：采用纯原生 Swift 5.9+ 与 SwiftUI 开发，内存常驻仅 ~30MB，CPU 占用趋近于 0%。
* **液态玻璃美学**：融合 macOS 26 Fluid Liquid Glass 现代美学，3D 动态晶体发光球体与粒子光效，兼具极致视觉与丝滑交互。
* **双语支持**：全界面 1:1 中英文双语无缝即时切换（`简体中文 / English`）。

### 2. 🧹 深度全盘安全清理与应用彻底卸载 (Deep Clean & Smart Uninstaller)
* **8 大深度清理引擎**：
  * 系统日常运行缓存与系统日志
  * 大文件与安装包、开发构建缓存（Xcode DerivedData、Cargo、Go 等）
  * 隐私痕迹与通讯媒体缓存（微信、Telegram、QQ、浏览器缓存）
  * 已卸载应用孤儿残留文件（精确扫描 `~/Library` 残留配置与支持文件）
* **0 误删安全护盾**：内置三层白名单防护与动态安全拦截，绝对不触碰钥匙串、系统关键文件与用户重要数据库。
* **应用一键拖拽卸载**：支持将 `.app` 拖入窗口一键彻底搜寻并剥离全部关联残留。

### 3. 🌐 独家精准流量与代理模式识别 (Smart Traffic & Proxy Telemetry)
* **秒级精准探测**：实时辨析当前网络链路状态：
  * 🔵 **普通直连 (Direct)**：未启用代理时即刻接管，显示标准直连。
  * 🟢 **规则分流 (Rule Routing)**：智能识别 v2rayN、Clash、Mihomo、Surge 等分流策略，直接读取本地代理客户端 SQLite 配置。
  * 🔴 **全局代理 (Global Proxy)**：全局接管所有流量时清晰标红警示。
* **状态栏/主控台双向监控**：毫秒级实时上传/下载速率计算与 SoC 芯片温度感知。

### 4. 🛡️ 深度私密安全保险箱 (Privacy Stealth Vault)
* **全隐形隐匿技术**：将敏感私密文件或文件夹拖入保险箱后，文件将在访达（Finder）与终端中**彻底隐匿消失**。
* **零云端泄露风险**：所有数据与加密逻辑 100% 运行在本地设备，零网络上传。
* **Touch ID / 本地主密码门禁**：支持指纹一键解锁，解锁后自动在访达中定位实体，上锁后瞬间隐形。

---

## 🖥️ 模块一览

| 模块 | 功能说明 |
| :--- | :--- |
| **智能清理 (Smart Clean)** | 首页 3D 悬浮座舱，4 颗环绕微型舱精准下钻，一键极速扫描与安全瘦身 |
| **应用卸载 (Uninstaller)** | 拖拽即卸、全盘已安装应用索引、关联配置文件彻底剥离 |
| **系统监测 (System Monitor)** | CPU/内存双环形监控、4 通道温度传感器、多磁盘存储卷、实时网速与代理状态 |
| **隐私保险箱 (Privacy Vault)** | 拖拽隐形私密文件、Touch ID 极速解锁、多文件秒级搜索与安全保护 |
| **状态栏常驻卡片 (Menu Bar)** | 顶部菜单栏实时网速（↓↑）、SoC 温度与快捷一键清理 |

---

## 🛠️ 快速开始

### 运行环境
* **macOS 14.0 (Sonoma)** 及以上版本
* 支持 **Apple Silicon (M1/M2/M3/M4 系列)** 与 **Intel** 芯片

### 源码编译
```bash
git clone https://github.com/purestudio/MacAegis.git
cd MacAegis

# 编译 Debug 二进制
swift build

# 运行应用
.build/arm64-apple-macosx/debug/MacAegisApp
```

---

## 📄 开源许可证
MacAegis 采用 [MIT 许可证](LICENSE) 开源发布。

<p align="center">
  <img src="AppIcon.icns" width="108" height="108" alt="MacAegis Icon">
</p>

<h1 align="center">MacAegis</h1>

<p align="center">
  <b>专为 macOS 打造的原生极速隐私隐匿、智能深度清理与状态栏硬件监控神器</b><br>
  <sub>瞬时隐匿 · 彻底断尾 · 极简轻量 · 离线零上传 · 专为 Apple Silicon 芯片与 macOS 深度优化</sub>
</p>

<p align="center">
  <a href="README_EN.md">English Documentation</a> | <b>简体中文文档</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%2F%20Sequoia)-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Chip-Apple%20Silicon%20(M1%2FM2%2FM3%2FM4)%20%2F%20Intel-purple?logo=apple" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/Language-Swift%206%20Native-orange?logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/App%20Size-2.4%20MB%20Ultra--light-success" alt="App Size">
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%26%20Zero%20Tracking-emerald" alt="Privacy">
  <img src="https://img.shields.io/badge/License-Freeware-brightgreen" alt="License">
</p>

<p align="center">
  <a href="https://github.com/meowvia/MacAegis/releases/latest">
    <img src="https://img.shields.io/badge/🚀%20免费下载-MacAegis%20最新版%20(DMG%20%2F%20ZIP)-007AFF?style=for-the-badge" alt="下载 MacAegis">
  </a>
</p>

---

## 🌟 为什么选择 MacAegis？

在日常使用 Mac 时，我们常常面临三大痛点：
1. **私密文件无处藏身**：想要隐藏私密照片、工作草稿或财务报表，原生 macOS 只能手动敲繁琐终端命令，且容易在全局搜索中意外泄露；
2. **清理软件臃肿昂贵**：传统第三方清理工具动辄几百兆后台常驻、强制按年订阅收费，还可能误删开发与用户核心数据；
3. **硬件监控分散杂乱**：想看 CPU 温度、风扇转速和磁盘剩余，还要安装各种割裂的插件。

**MacAegis 为此而生**——以不到 **2.4 MB** 的极致轻量体积，将 **「隐私隐匿」**、**「智能深度清理」**、**「应用彻底卸载」** 与 **「状态栏全景监控」** 融为一体。零常驻后台、零数据上传，把 Mac 的掌控权真正还给用户。

---

## 📸 核心功能展示

### 1. 🛡️ 隐私隐匿 (Privacy Conceal) · 瞬时隐形与硬件级防误删
支持将敏感文件与文件夹一键隐匿，从访达（Finder）、聚焦搜索（Spotlight）以及第三方软件中彻底隐形。
- **批量管理与分类查看**：支持按「全部 / 文件夹 / 单体文件」独立切换筛选，支持全局全选与一键批量锁定/解锁；
- **生物识别与灾难恢复**：支持 Touch ID 指纹一键瞬时解锁与加密灾难恢复码（带 Checksum 防错机制）；
- **内核级防误删硬约束**：处于隐匿状态的文件在智能清理时**自动深度过滤**，绝不误伤或泄露。

<p align="center">
  <img src="docs/screenshots/vault_locked.png" width="820" alt="MacAegis 隐私隐匿锁定主界面">
</p>

<p align="center">
  <img src="docs/screenshots/vault_folder.png" width="820" alt="文件夹与单体文件分类管理">
</p>

---

### 2. ⚡ 智能清理 (Smart Clean) · 深度扫描与外置存储支持
以毫秒级速度扫描系统缓存、开发衍生文件、已卸载残留与大文件镜像。
- **安全白名单防护**：内置严苛白名单，永不误碰系统内核、用户配置或关键数据库；
- **外置移动硬盘感知**：自动识别移动硬盘中的大文件与外置废纸篓，带有醒目标签且默认安全不勾选。

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="820" alt="智能清理全景仪表盘">
</p>

---

### 3. 📦 应用卸载 (App Uninstaller) · 渐进式折叠明细与断尾清理
告别“把软件拖进废纸篓却留下几个 G 残留”的烦恼。
- **渐进式明细展开**：点击应用名称即可平滑展开其深层文件架构（主程序包、沙盒容器、应用数据、缓存、偏好设置、自启服务等）；
- **一键访达定位**：每个细项均支持在访达中精准定位核验；
- **进程智能熔断**：卸载前自动优雅退出后台残留进程与自启动守护脚本。

<p align="center">
  <img src="docs/screenshots/uninstaller.png" width="820" alt="应用卸载与多层级残留分析">
</p>

---

### 4. 📊 状态栏全景遥测 (Menu Bar Telemetry) · 精准对齐与优雅悬浮
常驻顶部菜单栏，点击即现透明毛玻璃全景监控卡片。
- **SoC 核心温度与风扇实时转速**：原生读取 Apple 硬件传感器，数据真实精准；
- **CPU 负载与统一内存**：实时掌握系统资源开销；
- **多磁盘动态感知**：与 macOS 访达计算标准完全对齐，动态呈现内置与外接磁盘可用空间；
- **网络实时上下行速率**：智能识别系统级代理模式。

<p align="center">
  <img src="docs/screenshots/menubar.png" width="340" alt="菜单栏状态卡片">
</p>

---

## 🆚 竞品特性横向对比

| 核心维度 | **MacAegis** | 传统商业清理软件 (如 CxxMyMac) | 开源单功能小工具 |
| :--- | :---: | :---: | :---: |
| **软件费用** | **完全免费** | 每年 200~400 元高额订阅 | 免费 |
| **安装包体积** | **2.4 MB** (极致轻量) | 120 MB ~ 250 MB (庞大臃肿) | 10 MB ~ 50 MB |
| **隐私隐匿保险箱** | ✅ **原生瞬时隐形 + 硬件密钥** | ❌ 无此功能 | ❌ 需另装加密软件 |
| **外置移动硬盘扫描** | ✅ **智能识别 + 默认防误删** | ⚠️ 部分支持 | ❌ 无 |
| **应用残留展开定位** | ✅ **渐进式手风琴折叠 + 定位** | ⚠️ 界面复杂 | ❌ 仅粗暴删除 |
| **后台资源消耗** | **0% 后台常驻守护进程** | ❌ 强驻后台后台监听 | 0% |
| **数据隐私安全** | **100% 本地离线，零联网上传** | ⚠️ 上传统计分析数据 | 视项目而定 |

---

## 📥 下载与安装指南

### 系统要求
- **操作系统**：macOS 14.0 (Sonoma) / macOS 15.0 (Sequoia) 及更高版本；
- **架构支持**：原生适配 Apple Silicon（M1 / M2 / M3 / M4 全系列），兼容 Intel 架构。

### 一键安装
1. 前往 **[GitHub Releases 官方发布页](../../releases)** 下载最新版本的 `MacAegis-vX.Y.Z.dmg` 或 `MacAegis-vX.Y.Z.zip`；
2. 打开 DMG 镜像，将 **MacAegis.app** 拖入 **Applications（应用程序）** 文件夹即可使用。

> **提示**：未做苹果付费开发者证书签名，初次在 Mac 打开若提示“已损坏”或“无法验证开发者”，在终端中执行一行命令即可解除隔离属性：
> ```bash
> xattr -cr /Applications/MacAegis.app
> ```
> （或者右键点击 App 选择「打开」并在「系统设置 -> 隐私与安全性」中点击「仍要打开」）

---

## 🔒 隐私与安全性承诺

- **100% 离线运行**：MacAegis 不需要任何网络请求权限，绝不上云、不回传任何遥测日志或用户文件；
- **非侵入式操作**：所有清理和隐匿均遵循 macOS 标准系统安全边界，绝不篡改系统保护文件（SIP）。

---

## 💬 交流与反馈

如果您在使用过程中发现任何 Bug 或有新功能想法，欢迎随时提交 **[Issue 反馈](../../issues)**！
喜欢 MacAegis 的话，欢迎在右上角点一个 **⭐️ Star** 支持项目持续打磨！

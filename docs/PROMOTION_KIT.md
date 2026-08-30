# 🚀 MacAegis 官方全渠道中英文宣发物料包 (Launch & Marketing Kit)

> **说明**：本文件为 MacAegis 官方发布与社区推广物料，包含 GitHub Release 通告、技术社区推广贴、海外平台（Product Hunt / Twitter / Reddit）推文及竞品对比矩阵。随时可复制用于各大渠道发布！

---

## 📑 目录
1. [GitHub Release 发布说明 (中英文对照)](#1-github-release-发布说明)
2. [V2EX / 掘金 / 开发者社区宣发贴（主打硬核底层与轻量）](#2-v2ex--技术社区宣发帖)
3. [少数派 / 小红书 / 即刻社区推广贴（主打高颜值与隐私安全）](#3-少数派--小红书--即刻推广贴)
4. [Twitter (X) / Reddit (r/macapps) 英文国际化推文](#4-twitter--reddit-海外推广贴)
5. [四大核心硬指标与竞品对比表 (Feature Matrix)](#5-全方位竞品横向对比表)

---

## 1. GitHub Release 发布说明

### 🇨🇳 中文版 (Release Notes v1.0.0-Beta)

```markdown
# 🌊 MacAegis v1.0.0-Beta · 纯原生极速 macOS 系统管家与私密保险箱

我们很荣幸向大家介绍 **MacAegis** 的首个公开测试版！

市面上多数 Mac 清理工具动辄几百 MB 内存常驻，充斥着广告弹窗和误删风险。**MacAegis** 专为追求极致性能与设计美感的 Mac 用户打造：**100% 纯原生 Swift 5.9+ / SwiftUI 开发，Release 包体仅 3.5MB，零常驻系统负担，融合全景实时流量分流识别与硬件级隐私保险箱。**

### 🌟 核心杀手级特性

- ⚡ **100% 纯原生与极致轻量**：安装包仅 3.5MB，内存常驻仅 ~30MB，待机 CPU 0.0%，拒绝 Electron 臃肿。
- 🧹 **8 大维度深度安全清理**：系统运行缓存、崩溃日志、大文件与开发构建缓存（Xcode / Cargo / Go），内置 3 层严密白名单防护，绝不误删重要数据。
- 📦 **应用彻底卸载与残留追踪**：拖拽即卸，联动 LaunchServices 注册表精准剥离 `~/Library` 孤儿残留，支持 1.5s 进程占用强制回收。
- 🛡️ **深度私密安全保险箱**：4KB 就地文件头签名混淆 + `uchg` 不可变系统锁，在访达与终端中彻底隐匿（破解 `Cmd+Shift+.` 查看），支持 Touch ID 毫秒级无损还原。
- 🌐 **独家精准流量与代理分流动态识别**：直读系统协议栈与 `utun*` 路由，精准识别 `普通直连` / `规则分流` / `全局代理`。
- 🌡️ **状态栏轻量全景监控卡片**：毫秒级上下行网速、SoC 温度、风扇转速、统一内存与 Macintosh HD 存储状态一览无余。
- 🎨 **macOS 26 液态玻璃美学**：3D 悬浮水晶球与动态流光粒子，1:1 中英文双语即时无缝切换。

### 📥 下载体验
* **适用于**：macOS 14.0 (Sonoma) 及以上系统
* **支持架构**：Apple Silicon (M1/M2/M3/M4) 与 Intel 芯片
* 👉 [立即下载 MacAegis-v1.0.0-Beta.dmg](https://github.com/purestudio/MacAegis/releases)
```

---

### 🇺🇸 英文版 (Release Notes v1.0.0-Beta)

```markdown
# 🌊 MacAegis v1.0.0-Beta · Pure Native Lightweight macOS System Optimizer & Privacy Vault

We are thrilled to introduce the first Public Beta of **MacAegis**!

Unlike legacy Mac utilities that consume hundreds of megabytes of RAM via bloated Electron frameworks, **MacAegis** is engineered strictly with Swift 5.9+ and SwiftUI: **A 3.5MB lightweight binary with near-zero background overhead, instant deep cleanup, real-time proxy traffic telemetry, and a stealth privacy vault.**

### 💎 Key Highlights

- ⚡ **100% Pure Native & Ultra-Lightweight**: Only ~3.5MB release binary, ~30MB memory footprint, near 0% idle CPU.
- 🧹 **8-Dimension Deep & Safe Cleaner**: Intelligent cleanup for runtime caches, diagnostic logs, large archives, and build artifacts (Xcode / Cargo / Go) with a 3-tier zero-mistake whitelist safety shield.
- 📦 **App Uninstaller & Orphan Hunter**: Drag-and-drop uninstallation with LaunchServices registry validation to safely eliminate all orphan leftover configs in `~/Library`.
- 🛡️ **Deep Privacy Stealth Vault**: 4KB in-place binary header scrambling + `uchg` immutable lock to completely vanish private files from Finder and Terminal (defeating `Cmd+Shift+.`), supporting Touch ID instant bit-perfect restore.
- 🌐 **Dynamic Traffic & Proxy Telemetry**: Protocol-level dynamic detection of `Direct`, `Rule Routing`, and `Global Proxy` modes via `utun*` interfaces and `SCDynamicStore`.
- 🌡️ **Menu Bar Live Dashboard**: Real-time download/upload network meters, SoC thermal sensing, fan speed, unified memory, and disk usage.
- 🎨 **Fluid Liquid Glass Aesthetic**: Stunning macOS 26 fluid glass interface with 1:1 real-time Bilingual toggle (`Simplified Chinese / English`).

### 📥 Getting Started
* **Requirements**: macOS 14.0 (Sonoma) or later
* **Architecture**: Universal Binary (Apple Silicon M-Series & Intel)
* 👉 [Download MacAegis-v1.0.0-Beta.dmg](https://github.com/purestudio/MacAegis/releases)
```

---

## 2. V2EX / 技术社区宣发帖

**帖子标题**：`【开源/独立开发】受够了动辄 200MB 的 Electron 垃圾清理工具，我用纯 Swift 写了一款 3.5MB 的轻量系统管家 + 隐私保险箱 (求 V 友挑刺)`

**正文内容**：
```markdown
各位 V 友大家好！

作为长期 Mac 重度用户，我一直对市面上的 Mac 清理和监控工具感到非常头疼：
1. 要么基于 Electron 开发，开机常驻吃掉 300MB+ 内存，风扇狂转；
2. 要么动不动就搞全家桶弹窗、过度扫描甚至误删数据库和 Keychains；
3. 很多所谓的“文件隐藏”工具只是改了个文件名前缀，按 `Cmd+Shift+.` 一秒现形。

为了追求极致的纯粹与轻量，我利用业余时间用 **100% 纯原生 Swift 5.9+ / SwiftUI** 打造了 **MacAegis**。

### 🛠️ 技术亮点与底层实现：
1. **体积仅 3.5MB，内存仅 ~30MB**：
   - 彻底拒绝 Webview / Electron，纯原生系统 API 编译，待机 CPU 趋近于 0.0%。
2. **深度安全清理 + 孤儿残留猎手**：
   - 8 大维度扫描引擎（含 Xcode DerivedData、Cargo、Docker 镜像与应用卸载残留）；
   - 接入 LaunchServices 系统注册表（`NSWorkspace.urlForApplication`），即使 App 装在外接盘，其配置也绝不被误判为残留。
3. **隐私保险箱（真·就地混淆破坏）**：
   - 采用 `FileHandle` 对文件前 4KB Magic Header 进行就地可逆混淆 + 施加 `chmod 000` 与 `chflags uchg` 不可变系统锁；
   - 零磁盘额外占用，即使强制显示隐藏文件也无法预览、无法打开，解锁时 100% 比特级无损还原（SHA-256 完全一致）。
4. **实时网络流量与代理分流动态识别**：
   - 通过系统原生 `CFNetwork` / `SCDynamicStore` 和 `utun*` 虚拟接口路由表，实时秒级分辨当前网络是 `🔵 普通直连`、`🟢 规则分流` 还是 `🔴 全局代理`。

目前已打包为独立 Release 镜像，全功能 100% 免费开放公测，欢迎各位 V 友下载体验并多提宝贵意见！
```

---

## 3. 少数派 / 小红书 / 即刻推广贴

**标题**：`终于找到了一款颜值与实力并存的 Mac 原生清理神器！只有 3.5MB！`

**正文**：
```markdown
如果你也讨厌那些臃肿卡顿、动不动就弹广告的 Mac 清理软件，一定要试试这款小巧惊艳的纯原生系统神器 —— **MacAegis** 🌊

✨ **让人眼前一亮的 5 个理由**：
1. 🪶 **小到不可思议**：整个 App 只有 3.5MB！打开即用，内存占用几乎忽略不计，老款 M1 8G 也能丝滑起飞。
2. 🔮 **macOS 26 液态玻璃座舱**：超治愈的 3D 发光水晶球与动态流光，每一次清理都伴随清脆水滴音效，仪式感满满。
3. 🛡️ **私人专属隐形保险箱**：把私密文件/文件夹丢进去一键隐身，访达里直接消失！支持 Touch ID 指纹秒开，安全感拉满。
4. 🌐 **状态栏一眼看懂流量**：在顶部菜单栏实时看网速，还能一眼看出你的梯子是“直连”、“分流”还是“全局”。
5. 📦 **拖拽彻底卸载**：把不想用的 App 往里一拖，深层散落的残留配置文件全部一网打尽。

全功能免费体验中，中英文一键切换，Mac 强迫症党绝对会爱不释手！
```

---

## 4. Twitter / Reddit 海外推广贴

### Reddit (r/macapps / r/mac)
**Post Title**: `[Free Beta] I built a 3.5MB Pure Native macOS System Cleaner & Stealth Privacy Vault (No Electron, Zero Bloat)`

**Post Body**:
```markdown
Hey everyone! 👋

I was frustrated with legacy Mac cleaners consuming 300MB+ RAM and running bloated Electron frameworks in the background, so I built **MacAegis** from scratch using 100% pure Swift & SwiftUI.

### 🌟 What makes it different?
- **Ultra-Lightweight**: Entire binary is only 3.5MB with ~30MB memory footprint.
- **Stealth Privacy Vault**: Scrambles 4KB binary magic headers + `uchg` lock in-place. Files vanish from Finder and cannot be previewed even with `Cmd+Shift+.`, supporting Touch ID instant restore.
- **Smart Cleaner & Orphan Hunter**: 8 clean dimensions + LaunchServices registry integration so your custom app configs are never mistakenly deleted.
- **Proxy Telemetry**: Automatically detects Direct / Rule / Global proxy routing via `utun` interfaces and `SCDynamicStore`.
- **Fluid Glass UI**: Modern macOS liquid glass translucency with instant 1:1 English/Chinese toggle.

It's currently 100% free for Public Beta. Would love to get your feedback and thoughts!
```

---

## 5. 全方位竞品横向对比表

| 维度 / 特性 | 🌊 **MacAegis** | 🍋 Tencent Lemon | 🧼 CleanMyMac X | 🥋 Sensei | 🐾 Mole (tw93) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **底层开发架构** | **100% 纯原生 Swift 5.9+** | 原生 ObjC/Swift | 原生 + 混合组件 | 原生 Swift | Shell / 脚本 |
| **安装包/二进制体积** | ⚡ **~3.5 MB** | ~35 MB | ~150 MB+ | ~50 MB | < 1 MB (CLI) |
| **常驻内存占用** | 🍃 **~30 MB** | ~60 MB | ~200 MB+ | ~100 MB | 0 MB (非GUI) |
| **深度私密保险箱** | ✅ **4KB 就地特征混淆 + Touch ID** | ❌ 无 | ❌ 无 | ❌ 无 | ❌ 无 |
| **动态代理分流识别** | ✅ **直连 / 规则 / 全局动态探测** | ❌ 无 | ❌ 无 | ❌ 无 | ❌ 无 |
| **孤儿残留注册表核验** | ✅ **LaunchServices 0 误删保障** | ⚠️ 部分路径 | ⚠️ 自研规则 | ⚠️ 基础规则 | ⚠️ 基础规则 |
| **现代液态玻璃 UI** | ✅ **macOS 26 3D 水晶座舱** | 传统经典列表 | 扁平插画风 | 暗黑仪表盘 | 极简 CLI / 基础卡片 |
| **双语 1:1 即时响应** | ✅ **中英双语即时切换** | 仅中文 | 多国语言 | 英文为主 | 中文为主 |


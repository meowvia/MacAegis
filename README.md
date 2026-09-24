# 🛡️ MacAegis

<p align="center">
  <img src="assets/logo.png" width="100" height="100" alt="MacAegis Logo" />
</p>

<p align="center">
  <strong>一款纯原生 Swift 编写的 Mac 隐私文件隐匿与轻量系统维护工具</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?style=flat-square" alt="Swift" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%7C%200%20Telemetry-brightgreen?style=flat-square" alt="Privacy" />
  <img src="https://img.shields.io/badge/License-Freeware-purple?style=flat-square" alt="License" />
</p>

<p align="center">
  <a href="#-功能概览与界面预览">功能预览</a> •
  <a href="#-安装使用与常见问题">安装指南</a> •
  <a href="#-下载体验">下载地址</a> •
  <a href="README_EN.md">English Version</a>
</p>

---

## 📖 软件介绍

平时使用 Mac 时，总有些私人工作文件或重要文件夹不想被别人随手翻看。**MacAegis** 为此而生，提供**独立空间文件保护、智能系统清理与应用深度卸载**：

* **独立空间**：将敏感文件夹或私人文件拖入，即可原位隐形并阻止快速预览，支持 Touch ID 指纹秒级解锁；
* **视觉体系**：全面拥抱 macOS 原生流动玻璃（Liquid Glass）视觉架构，顶栏一体化贯通，通透轻盈；
* **应用卸载**：深度扫描应用关联残留与孤立配置，支持权限提升彻底卸载；
* **系统维护**：精准扫描各类系统与开发缓存，识别闲置大文件与外接存储；
* **干净克制**：纯本地离线运行，零数据上传，退出即完全释放系统资源。

---

## 📸 功能概览与界面预览 (Feature Showcase)

### 1. 核心主控台 (Dashboard)
直观展示系统整体健康度，提供一键智能清理入口与深度扫描反馈，支持外接磁盘容量识别。
<p align="center">
  <img src="assets/screenshots_v2/01_dashboard.png" width="800" alt="核心主控台" />
</p>

### 2. 空间解锁机制 (Vault Unlock)
接入 macOS 原生 Touch ID 与系统密码验证，安全阻断未经授权的访问请求。
<p align="center">
  <img src="assets/screenshots_v2/02_vault_unlock.png" width="800" alt="空间解锁机制" />
</p>

### 3. 独立空间 (Private Space)
提供私密文件与文件夹的原位安全隐匿保护，支持拖拽快速纳管，操作过程不产生冗余拷贝，不占用额外磁盘空间。
<p align="center">
  <img src="assets/screenshots_v2/03_vault_empty.png" width="800" alt="独立空间" />
</p>

### 4. 隐匿资产管理 (Concealed Assets)
对已保护的文件及文件夹进行结构化排布，实时反馈目标路径的锁定状态。
<p align="center">
  <img src="assets/screenshots_v2/04_vault_list.png" width="800" alt="隐匿资产管理" />
</p>

### 5. 批量状态控制 (Batch Operations)
支持多选与全局全选，一键完成海量文件的解除保护或重新锁定，操作耗时均在毫秒级。
<p align="center">
  <img src="assets/screenshots_v2/05_vault_batch.png" width="800" alt="批量状态控制" />
</p>

### 6. 灾备与安全须知 (User Notice & Recovery)
内置防呆设计与恢复码机制，确保用户在意外丢失权限或忘记密码时依然能够安全取回数据。
<p align="center">
  <img src="assets/screenshots_v2/06_vault_notice_1.png" width="800" alt="安全须知1" />
</p>
<p align="center">
  <img src="assets/screenshots_v2/07_vault_notice_2.png" width="800" alt="安全须知2" />
</p>

### 7. 深度应用卸载 (Deep Uninstaller)
穿透系统沙盒，精准定位并枚举系统中已安装的应用及其物理占用体积。
<p align="center">
  <img src="assets/screenshots_v2/08_uninstaller_list.png" width="800" alt="深度应用卸载" />
</p>

### 8. 孤立残留粉碎 (Leftover Crushing)
自动追踪已卸载程序的底层残留文件（含群组容器与偏好设置），支持通过特权提升执行无死角清理。
<p align="center">
  <img src="assets/screenshots_v2/09_uninstaller_leftovers.png" width="800" alt="孤立残留粉碎" />
</p>

### 9. 偏好设置 (Preferences)
支持跟随系统级别的深浅色模式自动切换，提供中英双语无缝热重载及自定义硬件监测偏好。
<p align="center">
  <img src="assets/screenshots_v2/10_settings_light.png" width="800" alt="深浅色模式支持" />
</p>
<p align="center">
  <img src="assets/screenshots_v2/11_settings_en.png" width="800" alt="中英双语支持" />
</p>

### 10. 状态栏硬件监控 (Menubar Telemetry)
采用低耗内核级轮询技术，实时呈现芯片核心温度、风扇转速及多态内存占用。
<p align="center">
  <img src="assets/screenshots_v2/12_menubar.png" width="360" alt="状态栏硬件监控" />
</p>

---

## 🚀 安装使用与常见问题

### 1. 标准安装步骤
#### 选项 A：通过 Homebrew 一键安装（推荐 · 极客首选）
```bash
brew install meowvia/tap/macaegis
```

#### 选项 B：手动下载安装（含一键覆盖更新与权限重置机制）
1. 在 [Releases 发布页面](https://github.com/meowvia/MacAegis/releases) 下载最新的 `MacAegis-vX.Y.Z.dmg` 安装包；
2. **首次安装**：双击挂载 DMG 镜像后，将 **MacAegis** 拖入「➡️ 拖拽至此安装」快捷方式即可；
3. **覆盖更新（强烈推荐）**：打开 DMG 镜像后，直接双击运行内置的 `Update Assistant (更新助手).command`，程序将自动终止旧版后台进程、清理系统注册缓存并完成无缝替换；
4. 在启动台或访达「应用程序」中直接打开 MacAegis 即可开始使用。

---

### 2. 遇到“应用已损坏 / 无法验证开发者”如何解决？

由于本软件属于个人独立开源项目，采用本地自签名机制（未加入苹果付费企业开发者计划），首次打开时 macOS Gatekeeper 安全机制可能会弹出拦截提示：
> *“「MacAegis」已损坏，无法打开。你应该将它移到废纸篓。”* 或 *“无法打开，因为无法验证开发者”*

**解决办法（只需执行一次）：**
1. 打开系统自带的 **终端（Terminal）** 应用程序（可在聚焦搜索 Spotlight 中输入 Terminal 打开）；
2. 复制并粘贴以下命令后按回车执行（如提示输入密码，直接输入开机密码即可）：
```bash
sudo xattr -rd com.apple.quarantine /Applications/MacAegis.app
```
3. 重新打开 MacAegis 即可正常运行。

---

### 3. 完全磁盘访问权限（FDA）与覆盖更新重置须知
为了能够正常扫描系统缓存残留并在访达中定位深层文件，首次使用清理或卸载功能时，需要开启系统的 **完全磁盘访问权限 (Full Disk Access)**：
* 打开 **系统设置** → **隐私与安全性** → **完全磁盘访问权限**，找到 **MacAegis** 并勾选开启。
* **⚠️ 覆盖更新重要须知**：受 macOS 底层安全机制（TCC）对自签名程序代码哈希（CDHash）的校验规则影响，每次覆盖更新二进制后，系统设置中旧的授权会在底层静默失效（即便显示勾选状态）。**重装或更新用户请务必在【完全磁盘访问权限】列表中，先选中旧的 MacAegis 点击减号【-】移除，再点击加号【+】重新添加 `/Applications/MacAegis.app` 开启授权**，否则可能无法扫描深度系统缓存。使用安装包内的更新助手可一键直达该设置页面。

---

## 📦 下载体验

* **GitHub 最新版本**：[MacAegis Releases](https://github.com/meowvia/MacAegis/releases)
* **系统要求**：macOS 14.0 (Sonoma) 或更高版本，兼容 Apple Silicon (M1/M2/M3/M4) 及 Intel 机型。

---

## 📄 许可说明

MacAegis 是一款免费独立软件。所有功能均在本地运行，欢迎下载体验并提交反馈与建议！



所有关键版本的更新与修复记录将在此文档中严格对齐官方发布说明。

---

## [v1.0.0]

**MacAegis v1.0.0 更新说明**

⚠️ **重要提示**：作为大版本升级，受 macOS 签名机制限制，覆盖更新可能会导致系统的完全磁盘访问权限 (FDA) 失效。建议使用安装包内的更新助手进行更新；更新后请在系统设置中将旧的 MacAegis 授权移除并重新添加开启。首次打开若遇未验证提示，按住 Control 键点击“打开”即可。

本次更新为 MacAegis 1.0.0 正式大版本，全面换代为现代流动玻璃（Liquid Glass）视觉体系，并对多项核心功能交互与稳定性进行了集中重构与修复。

**修改**
* 全面换代为 macOS 原生流动玻璃（Liquid Glass）视觉架构与一体化贯通顶栏。
* 将“隐私保险箱”更名为“独立空间”，界面标签统一对齐为四字规范。
* 安装包内新增更新助手程序与双语权限配置指引。

**修复**
* 修复了顶部栏双击缩放窗口的系统交互失效问题，并解决了窗口拉伸时的形变瑕疵。
* 修复了部分情况下列表图标解码与渲染可能引起的界面轻度掉帧与卡顿。
* 修复了应用卸载提示信息在特定场景下的视觉重叠问题。
* 修复了清理模块偶发误扫描受保护私密文件的问题。

**优化**
* 优化了大文件扫描逻辑与外接存储设备的文件检索支持。
* 优化了应用卸载与残留文件的扫描识别精度，进一步提升清理安全性。
* 优化了硬件温控与风扇转速的读取开销，降低后台待机能耗。
* 优化了初次启动时界面的语言智能匹配与切换引导逻辑。

**MacAegis v1.0.0 Release Notes**

⚠️ **Important Notice**: As a major version upgrade, due to macOS signature constraints, overwriting with a new version may invalidate your existing Full Disk Access (FDA) permissions. It is recommended to use the included Update Assistant; after updating, please remove the old MacAegis entry in System Settings and re-add it. For first-time launches encountering an unverified developer warning, hold the Control key and click "Open".

Version 1.0.0 is a major milestone for MacAegis, fully embracing the modern Liquid Glass visual design while delivering focused refinements and stability fixes across core modules.

**Modifications**
* Fully transitioned to macOS native Liquid Glass visual architecture with a unified titlebar.
* Renamed "Privacy Vault" to "Private Space" with balanced four-character tab labeling.
* Added the Update Assistant utility and bilingual permission guidance inside the installer package.

**Fixes**
* Fixed an issue where double-clicking the titlebar failed to zoom the window, and resolved window resizing distortion.
* Fixed occasional frame drops and micro-stutters during list loading and icon rendering.
* Fixed a visual overlap bug with uninstaller completion toast messages under certain conditions.
* Fixed an edge case where protected private files could be inadvertently scanned during routine cleaning.

**Optimizations**
* Optimized large file discovery and expanded scanning support for external storage devices.
* Optimized residual leftover detection accuracy during application uninstallation for safer removal.
* Optimized thermal and fan telemetry polling to further reduce background standby power consumption.
* Optimized initial launch language auto-detection and locale switcher guidance.

---

## [v0.2.3]

**MacAegis v0.2.3 更新说明**

⚠️ **重要提示**：受 macOS 系统签名验证机制限制，覆盖升级新版本可能会导致原有的完全磁盘访问权限 (FDA) 失效。如果遇到权限变灰，请进入系统偏好设置删除旧记录后重新添加。首次安装的新用户如遇“无法验证开发者”拦截，请在访达中按住 Control 键点击“打开”，或直接运行安装包内的更新助手。

**修改**
* 彻底移除了状态栏的网速实时监控与流量识别模块，回归纯净体验。
* 更改了设置页面中底层权限状态的检测与验证逻辑。

**修复**
* 修复了在卸载深层关联较多的大型应用时，可能导致进度条停止响应的问题。
* 修复了卸载受保护的系统级残留文件时无法正常移入废纸篓的问题。
* 修复了由于系统缓存导致覆盖更新后，启动台 (Launchpad) 可能会出现重复图标的问题。

**优化**
* 优化了完全磁盘访问权限 (FDA) 的状态同步速度，授权后切回应用即可自动刷新。
* 优化了应用的底层后台监控机制，通过做减法进一步降低 CPU 性能占用。
* 优化了卸载过程中请求 macOS 提权（输入密码）时的交互规范。

**MacAegis v0.2.3 Release Notes**

⚠️ **Important Notice**: Due to macOS signature verification constraints, overwriting with a new version may invalidate your existing Full Disk Access (FDA) permissions. If this occurs, please remove the old record in System Settings and add the app again. For new users encountering an "unverified developer" warning, please hold the Control key and click "Open" in Finder, or simply run the included Update Assistant.

**Modifications**
* Completely removed the real-time network speed monitor and traffic routing module to maintain a pure and native experience.
* Changed the detection and validation logic for permission authorization status in the Settings page.

**Fixes**
* Fixed an issue that could cause the uninstaller to stop responding when deeply scanning very large applications.
* Fixed an issue where protected system leftover files could not be successfully moved to the Trash.
* Fixed a system cache issue that could cause duplicate icons to appear in the Launchpad after a software update.

**Optimizations**
* Optimized the state synchronization speed of Full Disk Access, allowing automatic refresh upon returning to the app.
* Optimized the underlying background monitoring mechanisms to further reduce CPU performance overhead.
* Optimized the interaction standards when requesting macOS privilege escalation (password prompt) during uninstallation.

---

## [v0.2.2]

**MacAegis v0.2.2 更新说明**

⚠️ **重要提示**：修复了 macOS 从 26 升级到 27 beta 版本下可能导致 App 一直卡在“授权界面”的兼容性问题，点击已经授权或暂不授权仍可以进入隐私隐匿中心管理文件，同时强烈建议你临时解除文件保护后一键升级安装更新（你的隐藏文件绝对安全）。

**修改**
* 调整了部分功能的提示文案。
* 更改了新版本检测的提示方式。
* 精简了主界面的部分视觉动画。

**修复**
* 修复了升级最新 macOS 后可能卡在授权界面无法进入主界面的Bug。
* 修复了卸载受保护应用时可能受阻的问题。
* 修复了应用列表状态无法实时同步的问题。

**优化**
* 优化了隐私空间的解锁交互体验与排版布局。
* 优化了全局权限引导流程，减少多余操作。
* 完善了密码验证的安全防范机制。

**MacAegis v0.2.2 Release Notes**

⚠️ **Important Notice**: Fixed a compatibility issue when upgrading from macOS 26 to macOS 27 Beta that could cause the app to get stuck on the "Authorization" screen. By clicking "I have authorized" or "Skip", you can still enter the Privacy Vault to manage your files. We strongly recommend temporarily removing file protection before performing a one-click upgrade to this version (your hidden files are completely safe).

**Modifications**
* Adjusted select prompt text and copywriting.
* Changed the notification method for new version updates.
* Simplified visual animations on the main interface.

**Fixes**
* Fixed a critical bug on the latest macOS where users could get stuck on the authorization screen.
* Fixed an issue that could prevent the uninstallation of protected applications.
* Fixed an issue where the application list status would not sync in real time.

**Optimizations**
* Optimized the unlock interaction and layout of the Privacy Vault.
* Optimized the global permission authorization flow to reduce redundant steps.
* Enhanced the security prevention mechanisms for password verification.

---





---

## [v0.2.1]

***

# MacAegis v0.2.1 

## 🚀 核心升级 (Core Updates)

* **✨ UI 界面全面焕新 (UI Redesign)**
  带来全新的视觉与交互排版。界面更加直观、现代，让你在管理 Mac 时拥有更丝滑的操作体验。

* **🗑️ 激进的清理与卸载引擎 (Aggressive Clean & Uninstaller)**
  我们为“系统清理”和“应用卸载”换上了更加激进和深度的底层代码。现在，MacAegis 能够真正做到将流氓 App **连根拔起**；连系统深处那些最顽固、死皮赖脸删不掉的残留垃圾，也能被强行粉碎。这一次，为你释放出的可用空间将远超预期。

* **🛡️ 隐私隐匿再进化 (Vault Security & Layout Upgrades)**
  优化了隐私文件的管理视图和排版，查找与操作更加顺手。同时，底层安全级别大幅提升，真正实现极速“瞬间隐藏与上锁”。只要放入隐匿空间，哪怕是专业的第三方硬盘扫描软件，也休想窥探你的任何私密文件。

## 🐛 体验优化 (Improvements)
* 修复了一些已知的小 Bug，进一步提升了软件在后台挂机时的静默稳定性和省电表现。

---
*(English Version)*

# MacAegis v0.2.1

## 🚀 Core Updates

* **✨ UI Redesign**
  A brand-new visual and interactive layout. The interface is now more intuitive, modern, and provides a buttery-smooth experience when managing your Mac.

* **🗑️ Aggressive Clean & Uninstaller Engine**
  We’ve integrated a much more aggressive and deep-cleaning codebase for both System Clean and App Uninstallation. MacAegis now completely **uproots** apps and forcefully crushes the most stubborn, deeply hidden system junk. Prepare to free up significantly more disk space than ever before.

* **🛡️ Privacy Vault Evolution (Security & Layout)**
  Refreshed the layout for managing hidden files, making it much easier to use. We also massively upgraded the underlying security level, achieving true "instant stealth and locking." Once your files are in the Vault, they become completely invisible, even to professional third-party disk scanners.

## 🐛 Improvements
* Fixed minor known bugs and further optimized overall stability and battery efficiency during background operations.

---

## [v0.2.0]

# 🛡️ MacAegis v0.2.0 发布说明

### 1. 「隐私隐匿」全方位增强与交互升级
* **批量管理与分类筛选**：支持按「全部 / 文件夹 / 单体文件」独立筛选，支持全局多选与批量锁定、解锁或移出；
* **极简两态拖拽**：平时静态居中，拖入悬停时动态切换为「松开加入隐藏」（*Drop to Hide*），松手即刻统计反馈；
* **内置《用户须知》**：首次使用主动居中指引，强调离线恢复码安全与使用技巧，右上角常驻随时回看；
* **视觉升级**：Touch ID 图标升级为 1:1 Apple 官方经典红粉色质感。

### 2. 底层安全机制与云盘隔离防护 (P0 Security)
* **云盘绝对隔离拦截**：底层硬拦截 iCloud Drive、Dropbox、OneDrive 等云同步目录，杜绝云端同步死循环与数据冲突；
* **双层防误杀与防泄漏**：全盘扫描与垃圾清理引擎接入金库实时校验，物理级禁止误扫、误删受保护文件；
* **彻底切断假锁定风险**：会话锁定时立即 0ms 擦除内存密钥，点击操作无缝唤起 Touch ID / 密码认证接续执行。

### 3. 「应用卸载」渐进式明细与访达定位
* 点击应用即可展开深层文件架构（主程序包、沙盒容器、应用支持、缓存、偏好设置与自启项）；
* 每个子项均支持「一键在访达中定位」，同时保留极简的一键彻底卸载。

### 4. 新增外置硬盘大文件扫描与防护
* 深度整合至首页「大文件与安装包」及全盘扫描中，自动识别外接移动硬盘的大文件与废纸篓残留；
* 带有专属「外置存储」标识且默认安全不勾选，受保护的隐私文件绝不误扫。

### 5. 首页动态健康状态与呼吸感排版
* 扫描后根据系统冗余大小智能评估（严重冗余 ⚠️ / 适度优化 🧹 / 状态良好 ✨，扫描中动态流光）；
* 主标题字号优化至 28pt，规范副标题文案，状态徽标增加舒适的行距留白。

### 6. 状态栏硬件监控排版与算法校准
* 将 SoC 核心温度及风扇转速与 CPU 负载紧密搭档组合呈现，排版更符合直觉；
* 支持动态识别外置硬盘用量；磁盘可用容量统计与 macOS 访达实现 1:1 精准对齐。

=====================

# 🛡️ MacAegis v0.2.0 Release Notes

### 1. Privacy Vault Enhancements & Refined UX
* **Batch Operations & Category Filter**: Switch seamlessly between All / Folders / Files; multi-select items for 1-click batch lock, unlock, or removal;
* **Two-Phase Minimalist Dropzone**: Clean centered placeholder in idle state; transitions smoothly to "Drop to Hide" on drag-hover with instant Toast feedback;
* **Built-in User Notice Guide**: Centered safety guide on first setup covering recovery key tips and external download tool co-existence;
* **Visual Polish**: Upgraded Touch ID unlock button to Apple official classic coral/magenta styling.

### 2. Core Security Hardening & Cloud Storage Isolation (P0 Security)
* **Cloud Storage Hard Isolation**: Native path interception for iCloud Drive, Dropbox, OneDrive, and File Provider directories, preventing cloud sync loops and corruption;
* **Dual-Layer Anti-Accidental Deletion**: Scanning and cleaning engines strictly block locked private files from being scanned as cache or deleted;
* **Zero-Leak Session Security**: Wipes in-memory decryption keys upon locking; pending actions smoothly resume after Touch ID / password authentication.

### 3. App Uninstaller Progressive Disclosure & Reveal
* Expand app rows to inspect underlying binaries, sandbox containers, Application Support, caches, preferences, and launch agents;
* 1-click Finder reveal (`🔍 Reveal`) for every sub-item while maintaining 1-click complete uninstallation.

### 4. External Storage Deep Scanning & Protection
* Integrated into Big Files & Installers scanner, dynamically detecting clutter and Trash residuals across connected external drives;
* Labeled with dedicated external badges and unchecked by default for absolute safety.

### 5. Dynamic Health Assessment & Breathable Typography
* Evaluates system health post-scan (Clean Recommended ⚠️ / Optimize Available 🧹 / Good Condition ✨);
* Promoted hero title to 28pt with spacious breathing margins and unified branding.

### 6. Menu Bar Telemetry & Metric Alignment
* SoC core temperature and fan speed are now paired directly with CPU load for intuitive monitoring;
* Dynamically monitors external drive storage; free space metrics are precisely aligned with macOS Finder.

---

## [v0.1.1]



---


# 更新日志 (Changelog)

所有关键版本的更新与修复记录将在此文档中记录。

---

## [v0.2.3] - 2026-09-17

⚠️ **重要提示 (Important Notice)**
受 macOS 系统签名验证机制限制，覆盖升级新版本可能会导致原有的完全磁盘访问权限 (FDA) 失效。如果遇到权限变灰，请进入系统偏好设置删除旧记录后重新添加。首次安装的新用户如遇“无法验证开发者”拦截，请在访达中按住 Control 键点击“打开”，或直接运行安装包内的更新助手。
*(Due to macOS signature verification constraints, overwriting with a new version may invalidate your existing Full Disk Access permissions. If this occurs, please remove the old record in System Settings and add the app again. For new users encountering an "unverified developer" warning, please hold the Control key and click "Open" in Finder, or simply run the included Update Assistant.)*

### 修改 (Modifications)
* 彻底移除了状态栏的网速实时监控与流量识别模块，回归纯净体验。(Completely removed the real-time network speed monitor and traffic routing module to maintain a pure and native experience.)
* 更改了设置页面中底层权限状态的检测与验证逻辑。(Changed the detection and validation logic for permission authorization status in the Settings page.)

### 修复 (Fixes)
* 修复了在卸载深层关联较多的大型应用时，可能导致进度条停止响应的问题。(Fixed an issue that could cause the uninstaller to stop responding when deeply scanning very large applications.)
* 修复了卸载受保护的系统级残留文件时无法正常移入废纸篓的问题。(Fixed an issue where protected system leftover files could not be successfully moved to the Trash.)
* 修复了由于系统缓存导致覆盖更新后，启动台 (Launchpad) 可能会出现重复图标的问题。(Fixed a system cache issue that could cause duplicate icons to appear in the Launchpad after a software update.)

### 优化 (Optimizations)
* 优化了完全磁盘访问权限 (FDA) 的状态同步速度，授权后切回应用即可自动刷新。(Optimized the state synchronization speed of Full Disk Access, allowing automatic refresh upon returning to the app.)
* 优化了应用的底层后台监控机制，通过做减法进一步降低 CPU 性能占用。(Optimized the underlying background monitoring mechanisms to further reduce CPU performance overhead.)
* 优化了卸载过程中请求 macOS 提权（输入密码）时的交互规范。(Optimized the interaction standards when requesting macOS privilege escalation during uninstallation.)

---

## [v0.2.2] - 2026-09-11

⚠️ **重要提示 (Important Notice)**
修复了 macOS 从 26 升级到 27 beta 版本下可能导致 App 一直卡在“授权界面”的兼容性问题，点击已经授权或暂不授权仍可以进入隐私隐匿中心管理文件，同时强烈建议你临时解除文件保护后一键升级安装更新（你的隐藏文件绝对安全）。
*(Fixed a compatibility issue when upgrading from macOS 26 to macOS 27 Beta that could cause the app to get stuck on the "Authorization" screen. By clicking "I have authorized" or "Skip", you can still enter the Privacy Vault to manage your files. We strongly recommend temporarily removing file protection before performing a one-click upgrade to this version - your hidden files are completely safe.)*

### 修改 (Modifications)
* 调整了部分功能的提示文案。(Adjusted select prompt text and copywriting.)
* 更改了新版本检测的提示方式。(Changed the notification method for new version updates.)
* 精简了主界面的部分视觉动画。(Simplified visual animations on the main interface.)

### 修复 (Fixes)
* 修复了升级最新 macOS 后可能卡在授权界面无法进入主界面的Bug。(Fixed a critical bug on the latest macOS where users could get stuck on the authorization screen.)
* 修复了卸载受保护应用时可能受阻的问题。(Fixed an issue that could prevent the uninstallation of protected applications.)
* 修复了应用列表状态无法实时同步的问题。(Fixed an issue where the application list status would not sync in real time.)

### 优化 (Optimizations)
* 优化了隐私空间的解锁交互体验与排版布局。(Optimized the unlock interaction and layout of the Privacy Vault.)
* 优化了全局权限引导流程，减少多余操作。(Optimized the global permission authorization flow to reduce redundant steps.)
* 完善了密码验证的安全防范机制。(Enhanced the security prevention mechanisms for password verification.)

---





---

## [v0.2.0] - 2026-09-01

### 🛡️ 隐私隐匿与底层安全加固 (P0 Security)
* **云盘目录隔离与防损坏保护**：底层识别并跳过 iCloud、Dropbox、OneDrive、Google Drive 等云同步目录，避免云端同步引擎死循环或冲突。
* **双层防误删与金库保护**：扫描与清理引擎全面引入金库保护拦截，防止将已锁定的隐私文件误识别为系统缓存。
* **会话退出密钥安全清除**：会话锁定（`lockAll()`）或退出时立即清除内存密钥，避免持久常驻。
* **用户须知安全手册**：首次初始化进入主动居中弹出《用户须知》（恢复码保管、外部下载器写入避坑、原地保护原理），右上角常驻回看入口。

### 🎨 UI 界面与交互重构
* **首页动态健康状态智能评估**：根据系统冗余智能切换标题状态（严重冗余提示清理 ⚠️、适度提示优化 🧹、极佳提示良好 ✨，扫描中动态流光）。
* **首页视觉呼吸感升级**：大标题字号调优（28pt）、规范副标题、状态胶囊增加独立留白空间。
* **拖拽区域动静两态交互**：静态居中展示「拖入文件夹或文件到此处」（`Drop folders or files here`），悬停动态切换为「松开加入隐藏」（`Drop to Hide`），松手即刻弹出 Toast 统计反馈。
* **Touch ID 图标质感升级**：解锁旁指纹图标升级为 1:1 Apple 官方经典红粉色质感。
* **应用卸载渐进式折叠明细**：手风琴式展开应用关联数据、沙盒、缓存与偏好设置，支持一键在访达中精准定位。

---

## [v0.1.1] - 2026-08-31

### ✨ 新增与优化
* **可重复扫描能量气泡**：首页大圆气泡升级为可点击的扫描按钮，支持重复点击触发真实全盘深度扫描，鼠标悬停带有呼吸微光反馈。
* **双击状态栏唤起**：双击菜单栏常驻图标直接置顶激活主窗口，移除浮窗冗余按钮。
* **呼吸微光列表入口**：底部「查看全盘深度扫描列表」增加 Cyan/Indigo 双色呼吸流光引导动效，提升层级辨识度。
* **物理级无损瘦身**：安装包体积精简至 **2.4 MB**，发布 DMG 镜像压缩至 **1.7 MB**。

### 🐛 修复
* **钥匙串静默轻量化**：优化文件元数据读写逻辑，避免不必要的 macOS 授权密码弹窗打扰。
* **实时网速统计修复**：过滤非 `AF_LINK` 链路层地址，排除 `utun` 等虚拟隧道二次累加，修复开启代理或 VPN 时的流量重复计算问题。
* **动态应用识别**：消除应用扫描的永久内存缓存，引入 5s TTL 机制，修复运行期间新安装 App 无法被卸载器识别的 Bug。

---

## [v0.1.0] - 2026-08-30

### 🚀 初始版本发布
* **隐私保险箱**：支持文件与文件夹的原位瞬时隐匿与权限封锁，支持 Touch ID / 主密码 / 64位灾难恢复码。
* **菜单栏实时监控**：常驻菜单栏实时显示上下行网速、芯片温度、CPU 占用，智能识别直连/规则/全局代理状态。
* **智能清理引擎**：全盘扫描开发缓存、系统缓存、大文件与历史镜像。
* **应用深度卸载**：拖拽 App 自动扫描关联残留文件并支持多目录关联清理。

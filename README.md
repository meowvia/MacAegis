# MacAegis

<p align="left">
  <b>简体中文</b> | <a href="README_EN.md">English</a>
</p>

主要解决两件事：在菜单栏看清楚网络代理状态、快速藏文件，顺便带了个轻量的开发缓存清理和卸载功能。

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="850" alt="MacAegis 主控台">
</p>

---

## 做了什么

### 1. 菜单栏看网络代理状态
平时挂着代理工具，经常搞不清楚当前流量到底是直连还是走了代理。MacAegis 在菜单栏常驻显示上下行实时网速：
* 蓝色：普通直连 
* 绿色：规则分流 
* 红色：全局代理

直接从 macOS 系统底层读取网络状态，不依赖具体用的是哪一款代理客户端。

<p align="center">
  <img src="docs/screenshots/menubar.png" width="360" alt="菜单栏状态卡片">
</p>

### 2. 快速隐藏私密文件
避免投屏、外接显示器或者他人借用电脑，桌面和访达里的私密文件容易被瞄到：
* 把文件或文件夹拖进去就直接隐藏，访达里不显示，空格键快速预览也看不了。
* 采用原地流处理，不管几十兆还是百G文件夹/文件都可瞬间隐藏，不需要花时间复制大文件。
* 支持 TouchID 指纹+自设密码创建本地账户，TouchID+输入自设密码快速解锁，解锁后自动在访达中定位打开。
* 凭证保存在系统钥匙串中， 误删App，重新安装也能自动认领原先的文件，防止丢失。

<p align="center">
  <img src="docs/screenshots/vault.png" width="850" alt="隐私保险箱">
</p>

### 3. 随手清理与卸载
* 顺手清理 Xcode 编译缓存（DerivedData）、开发临时文件、日常日志和浏览器缓存。
* 拖入 App 自动找出散落在 Library 各个目录里的关联配置文件一起删除。

<p align="center">
  <img src="docs/screenshots/uninstaller.png" width="850" alt="应用卸载与清理">
</p>

---

## 系统要求与安装

* 纯 Swift 原生开发，体积绝对轻量，内存占用对老旧机型绝对友好。
* 支持 macOS 14.0 (Sonoma) 及以上系统，优先针对 Apple Silicon（M 系列芯片）开发，未针对 Intel 机型做充分测试。
* 前往 Releases 页面下载最新版本，解压后拖入“应用程序”文件夹。

> **提示**：未做苹果开发者付费公证，初次打开若提示“已损坏”或“无法验证开发者”，在终端执行一行命令解除隔离即可：
> ```bash
> xattr -cr /Applications/MacAegis.app
> ```
> （或者右键点击 App 选择「打开」并在「系统设置 -> 隐私与安全性」中点击「仍要打开」）

---

发现问题或有建议欢迎提 Issue 交流。

# MacAegis · Pure Native Lightweight macOS System Optimizer & Privacy Vault

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Memory%20Footprint-<%2040MB-brightgreen?style=flat-square" alt="Memory Footprint">
  <img src="https://img.shields.io/badge/License-MIT-purple?style=flat-square" alt="License">
</p>

---

## 🌟 Why MacAegis?

Most macOS system optimization and monitoring utilities are built on bloated Electron frameworks, consuming hundreds of megabytes of RAM while delivering cluttered UIs. **MacAegis** is engineered specifically for power users who demand uncompromising performance and modern design: **100% Pure Native Swift / SwiftUI, zero background overhead, lightning-fast deep cleaning, intelligent proxy traffic telemetry, and a hardware-level privacy vault.**

---

## 💎 Four Killer Pillars

### 1. ⚡ 100% Pure Native & Ultra-Lightweight
* **Say No to Electron Bloat**: Built strictly with Swift 5.9+ and SwiftUI. Memory footprint is only ~30MB, and idle CPU usage is near 0%.
* **Liquid Glass Aesthetic**: Features macOS 26 Fluid Liquid Glass translucency, dynamic 3D glowing crystal spheres, and fluid particle animations.
* **1:1 Bilingual Support**: Instant, real-time toggle between `简体中文` and `English`.

### 2. 🧹 Deep Safe Cleaning & Complete Uninstallation
* **8 Specialized Cleaner Engines**:
  * System runtime caches and diagnostic logs
  * Large downloads, archives, and developer build caches (Xcode DerivedData, Cargo, Go)
  * Privacy messaging traces (WeChat, Telegram, QQ, Browser caches)
  * Uninstalled app leftover configs and orphan files in `~/Library`
* **Zero-Mistake Whitelist Sentinel**: Multi-tier whitelist engine strictly protects Keychains, system foundations, and user databases.
* **One-Click Drag & Drop Uninstaller**: Drop any `.app` to automatically locate and cleanly eliminate all associated configuration leftovers.

### 3. 🌐 Intelligent Traffic & Proxy Routing Telemetry
* **Real-Time Link Inspection**:
  * 🔵 **Direct (普通直连)**: Instant fallback when proxies are disabled.
  * 🟢 **Rule Routing (规则分流)**: Real-time detection of routing rules across v2rayN, Clash, Mihomo, Surge via local SQLite database inspection.
  * 🔴 **Global Proxy (全局代理)**: High-visibility warning when all traffic is proxied.
* **Menu Bar & Cockpit Telemetry**: Millisecond-level upload/download speeds and SoC thermal monitoring.

### 4. 🛡️ Deep Privacy Stealth Vault
* **Complete Finder & Terminal Stealth**: Drop sensitive folders or files into the vault to make them completely vanish from Finder and Terminal.
* **Zero Cloud Leakage**: All vault metadata and security operations remain strictly on-device.
* **Touch ID & Master Password Gate**: Single-tap fingerprint unlock with instant Finder reveal; single-tap lock to stealth.

---

## 🛠️ Getting Started

### System Requirements
* **macOS 14.0 (Sonoma)** or later
* Compatible with both **Apple Silicon (M1/M2/M3/M4)** and **Intel** architectures

### Build from Source
```bash
git clone https://github.com/purestudio/MacAegis.git
cd MacAegis

# Build Debug Binary
swift build

# Launch Application
.build/arm64-apple-macosx/debug/MacAegisApp
```

---

## 📄 License
MacAegis is open-source software licensed under the [MIT License](LICENSE).

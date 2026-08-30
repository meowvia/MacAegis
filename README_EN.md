# MacAegis

> The ultra-lightweight native network telemetry, privacy vault, and system workbench built for macOS.

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.1.1--Beta-emerald?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Memory%20Footprint-~28MB-brightgreen?style=flat-square" alt="Memory Footprint">
  <img src="https://img.shields.io/badge/Binary%20Size-3.5MB-purple?style=flat-square" alt="Binary Size">
</p>

---

## 🎯 What Real Pain Points Does MacAegis Solve?

In daily office work, presentations, developer workflows, or screen sharing, Mac users frequently encounter these friction points:

| User Pain Point | Common Consequence | MacAegis Solution |
| :--- | :--- | :--- |
| **Ambiguous Network Routing** | Difficult to tell whether network traffic is currently direct, rule-routed, or going through a global proxy. | **System-Level Dynamic Telemetry**: Reads directly from the system network layer, independent of any proxy client; displays live transfer rates and 3-color status. |
| **Accidental Privacy Exposure** | Business contracts, financial records, personal photos, or sensitive projects can be easily glanced at in Finder or Recents during screen sharing. | **Instant Invisible Vault**: Drag-and-drop to conceal files and folders immediately. Files cannot be opened or previewed in Finder or QuickLook. |
| **Traditional Encryption is Slow & Fragile** | Heavy encryption tools require lengthy file copying, take up double disk space, and risk total file corruption if interrupted. | **Zero-Copy In-Place Concealment**: Whether 100MB or 100GB, files are protected and restored in milliseconds without massive I/O copying. |
| **Bloated Maintenance Cleaners** | Mainstream tools weigh 100MB+, consume 200MB~500MB of RAM, and install persistent background daemons. | **Ultra-light Native**: Single **3.5MB** binary, **~28MB** memory footprint, idle CPU **< 0.1%**, and zero background daemons. |
| **Deep Application Residue** | Dragging an App to the Trash leaves behind gigabytes of abandoned configuration and cache files in `~/Library`. | **Deep Associated Uninstaller**: Automatically indexes and purges all linked `Application Support`, `Caches`, and `Containers`. |

---

## 💎 Core Feature Matrix

### 1. 🌐 Network & Traffic Telemetry
* **Reads System Layer, Independent of Any Proxy Client**: Directly inspects macOS native system network state. Whether you use Clash, Surge, v2rayN, Shadowrocket, or macOS system network settings, it captures the real traffic routing state seamlessly.
* **3-Color Proxy Routing Status**:
  * 🔵 **Direct**: Standard non-proxied internet traffic.
  * 🟢 **Rule Routing**: Rule-based routing active.
  * 🔴 **Global Proxy**: Full traffic proxy active.
* **Live Transfer Rates**: Menu bar and dashboard indicators showing live upload and download throughput.

### 2. 🛡️ Privacy Vault
* **Instant In-Place Concealment**: Drag sensitive files or folders into the vault to immediately hide them from Finder and QuickLook previews.
* **Biometric Authentication**: Deep Touch ID fingerprint and master password integration for instant, secure access.
* **Zero Waiting & Zero Duplication**: Operates in-place without duplicating large video files or project directories.
* **Self-Recovery Resilience**: Reclaiming capabilities ensure your locked items remain safely restorable even after app reinstallation.

### 3. 🧹 Smart Clean
* **On-Demand Cache Scanning**: Safely cleans developer build artifacts (Xcode DerivedData, Cargo, etc.), application logs, and temporary caches.
* **Large Files & Packages**: Quickly discovers forgotten `.dmg`, `.pkg`, and large archives.
* **Safety Whitelist**: Built-in protection for critical system components, keychains, and databases.

### 4. 🗑️ Smart Uninstaller
* **Associated File Discovery**: Drag-and-drop to index and remove orphaned leftover configs across `~/Library`.
* **Automatic Process Recovery**: Automatically cleans up locked background processes during uninstallation.

---

## 💻 System Requirements

* **Operating System**: macOS 14.0 (Sonoma) or later
* **Hardware**: Apple Silicon (M1 / M2 / M3 / M4) and Intel Macs
* **Built With**: Swift 6 / SwiftUI / Native AppKit

---

## 📄 Repository & Feedback

* GitHub Repository: [https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)
* Licensed under the [MIT License](LICENSE).

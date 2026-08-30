# MacAegis

> The ultra-lightweight native privacy vault and system utility workbench built for macOS.

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.1.1--Beta-emerald?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Binary%20Size-3.5MB-purple?style=flat-square" alt="Binary Size">
</p>

---

## 🎯 What Real Pain Points Does MacAegis Solve?

In daily office work, screen sharing, presentations, or lending laptops, Mac users frequently encounter privacy concerns:

| User Pain Point | Common Consequence | MacAegis Solution |
| :--- | :--- | :--- |
| **Accidental Privacy Exposure** | Business contracts, financial records, personal photos, or sensitive projects can be easily glanced at in Finder or Recents during screen sharing. | **Instant Invisible Vault**: Drag-and-drop to conceal files and folders immediately. Files cannot be opened or previewed in Finder or QuickLook. |
| **Traditional Encryption is Slow & Fragile** | Heavy encryption tools require lengthy file copying, take up double disk space, and risk total file corruption if interrupted. | **Zero-Copy In-Place Concealment**: Whether 100MB or 100GB, files are protected and restored in milliseconds without massive I/O copying. |
| **Asset Loss from Accidental App Deletion** | If a user accidentally uninstalls a file-hiding app, protected files often become permanently lost or untrackable. | **Keychain-Backed Self-Recovery**: Backed by macOS Keychain credentials, reinstalling the app automatically recognizes user identity and seamlessly unlocks historical assets. |
| **Ambiguous Network Status** | Difficult to tell whether network traffic is currently direct, rule-routed, or going through a global proxy. | **Live Traffic Telemetry**: Real-time upload/download speeds and proxy routing indicators (Direct / Rule / Global) right in the menu bar. |
| **Accumulated System Clutter & Residue** | Systems collect temporary logs, developer build artifacts, and abandoned leftover configs from uninstalled apps over time. | **Lightweight Supporting Clean & Uninstall**: On-demand scanning and clean uninstaller to keep your Mac organized. |

---

## 💎 Key Capabilities

### 1. 🛡️ Core Spotlight: Privacy Vault
* **Instant In-Place Concealment**: Drag sensitive files or folders into the vault to immediately hide them from Finder and QuickLook previews.
* **Biometric Authentication**: Deep Touch ID fingerprint and master password integration for instant, secure access.
* **Zero Waiting & Zero Duplication**: Operates in-place without duplicating large video files or project directories.
* **Disaster Recovery Resilience**: Reclaiming capabilities ensure your locked items remain safely restorable even after app reinstallation.

### 2. 🌐 Live Network Telemetry
* **Native System-Level Dynamic Detection (Independent of Any Specific Proxy Client)**: Directly inspects macOS system networking states. Whether you use Clash, Surge, v2rayN, Shadowrocket, or macOS system network settings, it captures the real traffic routing state seamlessly.
* **Real-time Transfer Rates**: Lightweight menu bar indicator showing live upload and download activity.
* **3-Color Proxy Routing Status**:
  * 🔵 **Direct**: Standard non-proxied internet traffic.
  * 🟢 **Rule Routing**: Rule-based routing active.
  * 🔴 **Global Proxy**: Full traffic proxy active.

### 3. 🧹 Supporting Tools: Lightweight Cleaner & Uninstaller
* **Caches & Residue Cleaning**: On-demand cleaning for application logs, build caches (Xcode DerivedData, etc.), and temporary files.
* **Associated App Uninstaller**: Drag-and-drop to index and remove orphaned leftover configs in `~/Library`.
* **Native Lightweight Footprint**: Pure Swift 6 binary weighing only **3.5MB** with event-driven, minimal system resource overhead.

---

## 💻 System Requirements

* **Operating System**: macOS 14.0 (Sonoma) or later
* **Hardware**: Apple Silicon (M1 / M2 / M3 / M4) and Intel Macs
* **Built With**: Swift 6 / SwiftUI / Native AppKit

---

## 📄 Repository & Feedback

* GitHub Repository: [https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)
* Licensed under the [MIT License](LICENSE).

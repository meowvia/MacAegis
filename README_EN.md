# MacAegis

> The ultra-lightweight native system cleaner, hardware monitor, and privacy workbench built for macOS.

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

Many Mac users experience common friction with traditional maintenance utilities:

| User Pain Point | Common Consequence | MacAegis Solution |
| :--- | :--- | :--- |
| **Bloated Cleaners** | Mainstream tools weigh 100MB+, consume 200MB~500MB of RAM, and install persistent background daemons. | **Ultra-light Native**: Single **3.5MB** binary, **~28MB** memory footprint, **0.0%** idle CPU, and zero background daemons. |
| **Incomplete Residue Removal** | Dragging an App to the Trash leaves behind gigabytes of abandoned files in `~/Library`. | **Deep Associated Uninstaller**: Automatically analyzes all linked `Application Support`, `Caches`, and `Containers`, removing them cleanly. |
| **Risk of Accidental Data Loss** | Aggressive tools often mistakenly delete active app preferences or critical user data. | **Rigorous Safety Checks**: Cross-references macOS application registries; provides detailed drill-down previews and safety whitelists before cleaning. |
| **Privacy Exposure** | Sensitive work or personal files can be exposed during screen sharing or accidental Finder clicks. | **Instant Privacy Vault**: Immediate protection on drag-and-drop; prevents Finder previews; unlocks via Touch ID; includes disaster recovery resilience. |
| **Invisible Network Status** | Difficult to tell whether network traffic is currently direct or routed via proxy rules. | **Live Traffic Telemetry**: Real-time upload/download speeds and proxy routing indicators (Direct / Rule / Global) right in the menu bar. |

---

## 📦 Key Capabilities

### 1. Smart Clean
* **System & Developer Caches**: Safely cleans Xcode DerivedData, build artifacts, application logs, and browser caches.
* **Large Files & Packages**: Quickly discovers forgotten `.dmg`, `.pkg`, and large archives.
* **Orphan Residue Discovery**: Detects leftover configurations from previously uninstalled applications.
* **Safety Whitelist**: Built-in protection for critical system components, keychains, and databases.

### 2. Smart Uninstaller
* **Drag-and-Drop Removal**: Drag any application to index all associated files across the system.
* **Full Application Index**: Visual list of installed apps sorted by size and last modified date.

### 3. System Telemetry & Network Telemetry
* **Hardware Health**: Zero-overhead telemetry for CPU usage, unified memory pressure, swap space, and SoC temperature.
* **Proxy Status Indicator**:
  * 🔵 **Direct**: Standard non-proxied internet traffic.
  * 🟢 **Rule Routing**: Rule-based routing active.
  * 🔴 **Global Proxy**: Full traffic encapsulation.

### 4. Privacy Vault
* **Instant In-Place Protection**: Protects files and folders without waiting for large file duplication.
* **Biometric Authentication**: Seamlessly unlock with Touch ID or master password.
* **Disaster Recovery**: Reclaiming resilience even if the application is uninstalled and reinstalled.

---

## 💻 System Requirements

* **Operating System**: macOS 14.0 (Sonoma) or later
* **Hardware**: Apple Silicon (M1 / M2 / M3 / M4) and Intel Macs
* **Built With**: Swift 6 / SwiftUI / Native AppKit

---

## 📄 Feedback & Repository

* GitHub Repository: [https://github.com/meowvia/MacAegis](https://github.com/meowvia/MacAegis)
* Licensed under the [MIT License](LICENSE).

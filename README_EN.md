<p align="center">
  <img src="AppIcon.icns" width="108" height="108" alt="MacAegis Icon">
</p>

<h1 align="center">MacAegis</h1>

<p align="center">
  <b>A Blazing-Fast Native Privacy Conceal, Smart System Cleaner & Hardware Telemetry Tool for macOS</b><br>
  <sub>Instant Stealth · Deep Clean · App Uninstaller · 100% Offline & Private · Tailored for Apple Silicon & macOS Sonoma / Sequoia</sub>
</p>

<p align="center">
  <b>English Documentation</b> | <a href="README.md">简体中文文档</a>
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
    <img src="https://img.shields.io/badge/🚀%20Free%20Download-MacAegis%20Latest%20(DMG%20%2F%20ZIP)-007AFF?style=for-the-badge" alt="Download MacAegis">
  </a>
</p>

---

## 🌟 Why MacAegis?

1. **Protect Private Data Instantly**: Native macOS lacks a simple GUI way to hide sensitive documents and folders from Finder and Spotlight without risky commands.
2. **Goodbye to Bloatware**: Commercial cleaning utilities are often 200MB+ bloatware packed with background daemons, telemetry, and expensive annual subscriptions.
3. **Unified Monitoring**: No need to install separate plugins just to check CPU temperature, fan RPM, and mounted disk capacity.

**MacAegis combines Privacy Conceal, Smart Cleaning, App Uninstallation, and Menu Bar Telemetry into a native, ultra-lightweight 2.4 MB package.**

---

## 📸 Key Features

### 1. 🛡️ Privacy Conceal (Instant Stealth Vault)
Instantly conceal sensitive files and folders from Finder, Spotlight, and third-party apps.
- **Batch Management**: Segmented filters for "All / Folders / Single Files", global Select-All, and one-click batch lock/unlock.
- **Touch ID & Disaster Recovery**: Biometric unlocking and 80-char checksummed recovery codes.
- **Kernel-Level Anti-Leak Filter**: Hidden files are strictly excluded from all cleaning and scan results.

<p align="center">
  <img src="docs/screenshots/vault_locked.png" width="820" alt="MacAegis Privacy Vault">
</p>

---

### 2. ⚡ Smart System Clean & External Drive Support
Millisecond deep scan for application caches, development leftovers, system logs, and huge disk images.
- **Zero-Accident Whitelist**: Strict protection for system kernels, user configurations, and databases.
- **External Drive Detection**: Automatically identifies large files and trash bins on external storage (safely unchecked by default).

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="820" alt="Smart Cleaner Dashboard">
</p>

---

### 3. 📦 App Uninstaller with Progressive Breakdown
- **Accordion Breakdown**: Expand any app to inspect its underlying App Bundle, Containers, Application Support, Caches, Preferences, and Launch Agents.
- **Finder Reveal**: One-click shortcut to inspect any component in Finder.
- **Graceful Termination**: Auto-unloads background launch daemons before removal.

<p align="center">
  <img src="docs/screenshots/uninstaller.png" width="820" alt="App Uninstaller">
</p>

---

### 4. 📊 Menu Bar Telemetry Card
- **SoC Core Temp & Fan RPM**: Direct hardware sensor readings paired with CPU load.
- **RAM & Disk Storage**: Perfectly aligned with macOS Finder calculations.
- **Real-Time Network Monitor**: Displays upload/download speeds with proxy awareness.

<p align="center">
  <img src="docs/screenshots/menubar.png" width="340" alt="Menu Bar Card">
</p>

---

## 📥 Installation & Requirements

- **Supported OS**: macOS 14.0 (Sonoma) / macOS 15.0 (Sequoia) or later.
- **Architecture**: Apple Silicon (M1/M2/M3/M4) & Intel.

1. Download `MacAegis-vX.Y.Z.dmg` from **[GitHub Releases](../../releases)**.
2. Open the DMG and drag **MacAegis.app** into `/Applications`.

> **Note**: If macOS shows "unverified developer", run this command in Terminal to clear the quarantine flag:
> ```bash
> xattr -cr /Applications/MacAegis.app
> ```

---

## 💬 Feedback & Community

Found a bug or have a suggestion? Feel free to open an **[Issue](../../issues)**!
If you find MacAegis helpful, please consider giving it a **⭐️ Star** on GitHub!

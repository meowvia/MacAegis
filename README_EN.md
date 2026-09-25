# 🛡️ MacAegis

<p align="center">
  <img src="assets/logo.png" width="100" height="100" alt="MacAegis Logo" />
</p>

<p align="center">
  <strong>A Pure Swift Native macOS Utility for Instant File Stealth and Lightweight System Maintenance</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?style=flat-square" alt="Swift" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%7C%200%20Telemetry-brightgreen?style=flat-square" alt="Privacy" />
  <img src="https://img.shields.io/badge/License-Freeware-purple?style=flat-square" alt="License" />
</p>

<p align="center">
  <a href="#-feature-showcase">Feature Showcase</a> •
  <a href="#-installation--usage-guide">Installation Guide</a> •
  <a href="#-download">Download</a> •
  <a href="README.md">中文版本 (Chinese)</a>
</p>

---

## 📖 Introduction

**MacAegis** is a lightweight, high-performance native macOS utility crafted for **instant file concealment, deep application uninstallation, and system maintenance**:

* **Liquid Glass Native Design**: Written entirely in pure Swift 6, tuned for Apple Silicon and Intel. The distribution DMG is merely **~1.7 MB** with near-zero background idle overhead.
* **Instant Stealth Without Size Limits**: Features a "Private Space" workflow for instant, in-place concealment of files and multi-gigabyte directories, secured by Touch ID biometric auth and 64-char emergency keys.
* **Deep Cleanup & Leftover Analysis**: Traverses sandboxes and caches to cleanly remove applications and uncover orphaned remnants left behind by uninstalled software.
* **100% Offline with Zero Telemetry**: Operates strictly local. No network calls, zero data uploads, and **never reads or touches your private file contents**.

<p align="center">
  <br />
  <a href="https://wise.com/pay/me/nongjinshui">
    <img src="assets/wise_qr.png" width="130" alt="Support MacAegis on Wise" />
  </a>
  <br />
  <sub>☕️ <strong>Buy the Indie Developer a Coffee / 请独立开发者喝杯咖啡</strong></sub><br />
  <sub>Testing Wise cross-border channel workflows; any genuine support for continuous indie development is deeply appreciated ❤️</sub><br />
  <sub>(作为初涉海外生态的独立开发者，目前正测试 Wise 跨境渠道；若本工具对您有所帮助，由衷感谢任何真实支持)</sub>
</p>

---

## 📸 Feature Showcase

### 1. Smart Clean Dashboard
Provides an intuitive overview of storage health, offering one-click smart scanning for temporary caches, logs, and reclaimable junk, complete with large-file inspection.
<p align="center">
  <img src="assets/screenshots_en/01_dashboard.png" width="800" alt="Smart Clean Dashboard" />
</p>

### 2. Installed Applications
Clearly catalogs all installed applications on your Mac, displaying accurate physical disk footprints and bundle versions for quick search and Finder navigation.
<p align="center">
  <img src="assets/screenshots_en/02_uninstaller_apps.png" width="800" alt="Installed Applications" />
</p>

### 3. Application Leftovers & Residual Cleanup
Automatically tracks down orphaned configuration files, application support remnants, and sandbox caches left behind by uninstalled software to reclaim valuable space.
<p align="center">
  <img src="assets/screenshots_en/03_uninstaller_leftovers.png" width="800" alt="Application Leftovers" />
</p>

### 4. Private Space Verification & Unlock Screen
A minimalist, modern security gateway supporting native Apple Touch ID biometric authentication and master password access, with built-in recovery key reset support.
<p align="center">
  <img src="assets/screenshots_en/04_vault_lock.png" width="800" alt="Private Space Verification & Unlock Screen" />
</p>

### 5. Private Space Ingestion & Ready State
A clean ingestion canvas allowing you to drag and drop sensitive folders or files for instant in-place concealment, complete with a quick scan for existing hidden items.
<p align="center">
  <img src="assets/screenshots_en/05_vault_empty.png" width="800" alt="Private Space Ingestion" />
</p>

### 6. Preferences & Permission Controls
Provides system-level preference toggles including launch at login and close-window behavior, along with clear status indicators for Full Disk Access (FDA) and App Management.
<p align="center">
  <img src="assets/screenshots_en/06_preferences.png" width="800" alt="Preferences & Permission Controls" />
</p>

### 7. Concealed Assets Management
A structured repository displaying protected folders and files, item sizes (supporting massive 10GB–100GB+ directories), lock status capsules, and quick Finder reveals.
<p align="center">
  <img src="assets/screenshots_en/07_vault_concealed.png" width="800" alt="Concealed Assets Management" />
</p>

### 8. Batch Operations & Multi-Select
A flexible multi-select action bar enabling you to unlock, lock, or release protection across multiple concealed assets simultaneously for effortless file management.
<p align="center">
  <img src="assets/screenshots_en/08_vault_batch.png" width="800" alt="Batch Operations & Multi-Select" />
</p>

### 9. Menubar Telemetry Card
An ultra-lightweight status bar popup providing real-time hardware telemetry: SoC core temperature, fan speed, unified memory pressure, and mounted disk volume capacity.
<p align="center">
  <img src="assets/screenshots_en/09_menubar.png" width="360" alt="Menubar Telemetry Card" />
</p>

---

## 🚀 Installation & Usage Guide

### 1. Standard Installation

#### Option A: Install via Homebrew Cask (Recommended)
```bash
brew install meowvia/tap/macaegis
```

#### Option B: Manual DMG Download
1. Download the latest `MacAegis-vX.Y.Z.dmg` installer package from the [Releases Page](https://github.com/meowvia/MacAegis/releases);
2. **First-time Install**: Open the DMG image and drag **MacAegis** onto the "➡️ Drag to Install" shortcut;
3. **Upgrading (Recommended)**: Double-click `Update Assistant (更新助手).command` inside the DMG. The assistant will safely terminate older instances, update the application in place, and exit gracefully;
4. Launch MacAegis from Launchpad or Applications.

---

### 2. First-Time Launch & Security Notice

MacAegis is an independent freeware utility utilizing local Ad-Hoc code signing. If macOS Gatekeeper displays an "Unverified Developer" notice on initial launch:

**Quick Resolution:**
* In Finder's **Applications** folder, locate **MacAegis**, hold the **Control key** and click the icon, then select **"Open"** from the context menu and confirm;
* Or run this single command in **Terminal** to clear the quarantine attribute:
```bash
sudo xattr -rd com.apple.quarantine /Applications/MacAegis.app
```

---

### 3. Full Disk Access (FDA) Permission Notice

To allow deep inspection of system caches and app preferences, grant **Full Disk Access (FDA)** when prompted:
1. Open macOS **System Settings** → **Privacy & Security** → **Full Disk Access**;
2. Locate **MacAegis** in the list and toggle it on.
3. **⚠️ Important Notice for Upgrades**: Under macOS security architecture, permissions are strictly bound to the unique code signature of each build. When overwriting or updating MacAegis, if scanning results appear empty, simply remove the old MacAegis entry [-] in Full Disk Access, and click [+] to re-add `/Applications/MacAegis.app`. Running the included Update Assistant can also guide you directly to this pane.

---

## 📦 Download

* **GitHub Official Releases**: [MacAegis Releases](https://github.com/meowvia/MacAegis/releases)
* **System Requirements**: macOS 14.0 (Sonoma) or newer, natively compatible with Apple Silicon (M1/M2/M3/M4 series) and Intel Macs.

---

## 📄 Privacy & Licensing Notice

MacAegis is free software. All operations execute 100% locally on your Mac. It contains zero networking capabilities, never uploads any data, and **never reads or modifies the contents of your personal files**. Pure, transparent, and respectful of your privacy. Feedback and suggestions are warmly welcomed!


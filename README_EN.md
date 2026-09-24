# 🛡️ MacAegis

<p align="center">
  <img src="assets/logo.png" width="100" height="100" alt="MacAegis Logo" />
</p>

<p align="center">
  <strong>A Pure Native Swift Utility for File Privacy Concealment & Lightweight Maintenance on macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?style=flat-square" alt="Swift" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%7C%200%20Telemetry-brightgreen?style=flat-square" alt="Privacy" />
  <img src="https://img.shields.io/badge/License-Freeware-purple?style=flat-square" alt="License" />
</p>

<p align="center">
  <a href="#-feature-walkthrough--preview">Feature Preview</a> •
  <a href="#-installation--troubleshooting">Installation Guide</a> •
  <a href="#-download">Download</a> •
  <a href="README.md">中文版本</a>
</p>

---

## 📖 Introduction

When working on a Mac, you often have private documents or confidential folders you'd prefer to keep away from prying eyes. **MacAegis** is built specifically for this purpose, providing **Private Space file protection, smart system maintenance, and deep app uninstallation**:

* **Private Space**: Drag confidential folders or files into the app to instantly conceal them in-place and block QuickLook previews, with seamless Touch ID unlock;
* **Visual Architecture**: Completely embraces native macOS Liquid Glass design materials with a unified seamless titlebar;
* **Deep Uninstaller**: Analyzes application leftovers, associated group containers, and caches with root privilege escalation;
* **System Maintenance**: Reliably scans system caches, dev artifacts, and large dormant files across local and external storage;
* **Clean & Restrained**: 100% local and offline. Exiting the app completely releases system memory without persistent background daemons.

---

## 📸 Feature Showcase

### 1. Dashboard
Visually displays overall system health, providing a one-click smart clean entry and deep scan feedback with external disk capacity recognition.
<p align="center">
  <img src="assets/screenshots_v2/01_dashboard.png" width="800" alt="Dashboard" />
</p>

### 2. Vault Unlock Mechanism
Enforces native macOS Touch ID and system password verification, strongly blocking unauthorized access requests.
<p align="center">
  <img src="assets/screenshots_v2/02_vault_unlock.png" width="800" alt="Vault Unlock Mechanism" />
</p>

### 3. Private Space
Provides in-place concealment protection for private files and folders. Supports quick drag-and-drop import without redundant disk duplicates.
<p align="center">
  <img src="assets/screenshots_v2/03_vault_empty.png" width="800" alt="Private Space" />
</p>

### 4. Concealed Assets Management
Structurally organizes protected files and folders, providing real-time feedback on the lock status of target paths.
<p align="center">
  <img src="assets/screenshots_v2/04_vault_list.png" width="800" alt="Concealed Assets Management" />
</p>

### 5. Batch Operations
Supports multi-select and global select-all. Complete unlocking or relocking of massive amounts of files in milliseconds with a single click.
<p align="center">
  <img src="assets/screenshots_v2/05_vault_batch.png" width="800" alt="Batch Operations" />
</p>

### 6. User Notice & Disaster Recovery
Built-in idiot-proof design and recovery code mechanism to ensure users can safely retrieve data even if permissions are accidentally lost or passwords forgotten.
<p align="center">
  <img src="assets/screenshots_v2/06_vault_notice_1.png" width="800" alt="User Notice 1" />
</p>
<p align="center">
  <img src="assets/screenshots_v2/07_vault_notice_2.png" width="800" alt="User Notice 2" />
</p>

### 7. Deep Uninstaller
Penetrates system sandboxes to precisely locate and enumerate installed applications and their physical storage footprints.
<p align="center">
  <img src="assets/screenshots_v2/08_uninstaller_list.png" width="800" alt="Deep Uninstaller" />
</p>

### 8. Orphan Leftover Crushing
Automatically tracks low-level residual files of uninstalled programs (including group containers and preferences). Supports blind-spot-free cleaning via root escalation.
<p align="center">
  <img src="assets/screenshots_v2/09_uninstaller_leftovers.png" width="800" alt="Orphan Leftover Crushing" />
</p>

### 9. Preferences
Automatically adapts to system-level light/dark modes. Offers seamless hot-reloading for English/Chinese bilingual support and customizable hardware telemetry settings.
<p align="center">
  <img src="assets/screenshots_v2/10_settings_light.png" width="800" alt="Light and Dark Mode" />
</p>
<p align="center">
  <img src="assets/screenshots_v2/11_settings_en.png" width="800" alt="Bilingual Support" />
</p>

### 10. Menubar Telemetry
Utilizes low-latency kernel polling technology to display SoC core temperature, fan speed, and polymorphic memory usage.
<p align="center">
  <img src="assets/screenshots_v2/12_menubar.png" width="360" alt="Menubar Telemetry" />
</p>

---

## 🚀 Installation & Troubleshooting

### 1. Standard Installation
#### Option A: One-Line Install via Homebrew (Recommended)
```bash
brew install meowvia/tap/macaegis
```

#### Option B: Manual DMG Download (With One-Click Update Assistant)
1. Download the latest `MacAegis-vX.Y.Z.dmg` installer from the [Releases Page](https://github.com/meowvia/MacAegis/releases);
2. **First-time Install**: Open the DMG image and drag **MacAegis** onto the "➡️ Drag to Install" shortcut;
3. **Upgrading / Overwriting (Recommended)**: Double-click `Update Assistant (更新助手).command` inside the DMG. It gracefully terminates older processes, purges system cache, and seamlessly updates the app;
4. Launch MacAegis from Launchpad or Applications.

---

### 2. How to Resolve "App is damaged / Cannot verify developer"

As an indie open-source utility utilizing Ad-Hoc self-signing (without Apple's paid enterprise certificate), macOS Gatekeeper may display a security prompt on initial launch:
> *"'MacAegis' is damaged and can't be opened. You should move it to the Trash."* or *"Cannot open because the developer cannot be verified"*

**Resolution (Run once in Terminal):**
1. Open the built-in **Terminal** app (via Spotlight search: `Terminal`);
2. Copy, paste, and run the following command (enter your Mac login password if prompted):
```bash
sudo xattr -rd com.apple.quarantine /Applications/MacAegis.app
```
3. Re-open MacAegis to run smoothly.

---

### 3. Full Disk Access (FDA) Permission & Upgrade Reset Notice
To enable deep system cache inspection and file reveals in Finder, grant Full Disk Access when prompted:
* Open **System Settings** → **Privacy & Security** → **Full Disk Access**, locate **MacAegis** and toggle it on.
* **⚠️ Important Notice for Upgrades**: Under macOS TCC security architecture, permissions are strictly bound to the unique binary code hash (CDHash) of each build. When overwriting or updating MacAegis, previous FDA authorization becomes silently invalidated by macOS even if the toggle appears enabled. **Please remove the old MacAegis entry [-] in Full Disk Access, and click [+] to re-add `/Applications/MacAegis.app` and toggle it on**. Running the included Update Assistant can automatically take you straight to this settings pane.

---

## 📦 Download

* **GitHub Releases**: [MacAegis Releases](https://github.com/meowvia/MacAegis/releases)
* **System Requirements**: macOS 14.0 (Sonoma) or newer, fully compatible with Apple Silicon (M1/M2/M3/M4) and Intel Macs.

---

## 📄 License

MacAegis is free software. All operations run 100% locally on your Mac. Feel free to try it out and share your feedback!

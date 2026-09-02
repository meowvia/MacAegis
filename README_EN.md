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

When working on a Mac, you often have private documents or confidential folders you'd prefer to keep away from prying eyes. **MacAegis** is built specifically for this purpose, providing **instant file/folder stealth and instant recovery**:

* **Instant Stealth**: Drag folders or files into the app to instantly vanish them from Finder and block QuickLook spacebar previews;
* **Quick Unlock**: Restore access seamlessly using Touch ID biometric authentication or master password;
* **Lightweight Maintenance**: Integrates deep system cache cleaning, app uninstaller with progressive file inspection, and menu bar telemetry;
* **Clean & Restrained**: 100% local and offline. Exiting the app completely releases system memory without persistent background daemons.


---

## 📸 Feature Walkthrough & Preview

### 1. Privacy Conceal & Anti-Inspection

Conceal and lock sensitive folders and standalone files. Set up your master password on first launch, paired with a local disaster recovery key.

#### 1. Password Setup Initialization
<p align="center">
  <img src="assets/screenshots/01_vault_setup_password.png" width="800" alt="Master Password Setup" />
</p>

#### 2. Built-in User Notice & Safety Guide
Displays user onboarding instructions upon first entry, highlighting recovery key management and external download tool co-existence.
<p align="center">
  <img src="assets/screenshots/02_vault_user_notice_countdown.png" width="800" alt="User Notice Countdown" />
</p>
<p align="center">
  <img src="assets/screenshots/03_vault_user_notice_full.png" width="800" alt="User Notice Confirmed" />
</p>

#### 3. Concealed Vault List & Category Filtering
Organizes protected items with category filters (All / Folders / Files), featuring instant Toast confirmations on drag-and-drop addition.
<p align="center">
  <img src="assets/screenshots/04_vault_concealed_list.png" width="800" alt="Concealed Vault List" />
</p>

#### 4. Multi-Select Batch Operations with Safety Confirmation
Select multiple items to batch lock, unlock, or remove protection with secondary confirmation dialogues.
<p align="center">
  <img src="assets/screenshots/05_vault_batch_operations.png" width="800" alt="Batch Operations" />
</p>

---

### 2. Smart Cleaning Cockpit

Dynamically evaluates system health based on existing disk clutter, supporting 1-click quick cleaning, full deep scanning, and external drive detection.

<p align="center">
  <img src="assets/screenshots/06_dashboard_clean.png" width="800" alt="Smart Cleaning Cockpit" />
</p>

---

### 3. Preferences & Security Commitments

Customize system appearance (Light / Dark mode), switch between English and Chinese seamlessly, select temperature units, configure Trash monitoring, and manage Full Disk Access (FDA).

<p align="center">
  <img src="assets/screenshots/07_settings_general.png" width="800" alt="General Preferences" />
</p>
<p align="center">
  <img src="assets/screenshots/08_settings_security.png" width="800" alt="Security & Permissions" />
</p>

---

### 4. App Uninstaller with Progressive Disclosure

Drag or select apps to inspect underlying binaries, sandbox containers, Application Support, caches, and preference files, with 1-click Finder reveal (`🔍 Reveal`).

<p align="center">
  <img src="assets/screenshots/09_uninstaller_progressive.png" width="800" alt="App Uninstaller Progressive Disclosure" />
</p>

---

### 5. Real-Time Menu Bar Telemetry

Persistent menu bar card displaying real-time upload/download network speed, SoC core temperature, fan speed, unified memory pressure, and multi-volume disk storage.

<p align="center">
  <img src="assets/screenshots/10_menubar_telemetry.png" width="360" alt="Menu Bar Telemetry" />
</p>

---

## 🚀 Installation & Troubleshooting

### 1. Standard Installation
#### Option A: One-Line Install via Homebrew (Recommended)
```bash
brew install meowvia/tap/macaegis
```

#### Option B: Manual Zip Download
1. Download the latest `MacAegis-vX.Y.Z.zip` archive from the [Releases Page](https://github.com/meowvia/MacAegis/releases);
2. Double-click to unzip, and drag **MacAegis.app** into your **Applications** folder;
3. Launch MacAegis from Launchpad or Applications.

---

### 2. How to Resolve "App is damaged / Cannot verify developer"

As an indie freeware project without an enterprise Apple Developer certificate, macOS Gatekeeper may display a security prompt on initial launch:
> *"'MacAegis' is damaged and can't be opened. You should move it to the Trash."* or *"Cannot open because the developer cannot be verified"*

**Resolution (Run once in Terminal):**
1. Open the built-in **Terminal** app (via Spotlight search: `Terminal`);
2. Copy, paste, and run the following command (enter your Mac login password if prompted):
```bash
sudo xattr -rd com.apple.quarantine /Applications/MacAegis.app
```
3. Re-open MacAegis to run smoothly.

---

### 3. Full Disk Access (FDA) Permission
To enable deep system cache inspection and file reveals in Finder, grant Full Disk Access when prompted:
* Open **System Settings** → **Privacy & Security** → **Full Disk Access**, locate **MacAegis** and toggle it on.

---

## 📦 Download

* **GitHub Releases**: [MacAegis Releases](https://github.com/meowvia/MacAegis/releases)
* **System Requirements**: macOS 14.0 (Sonoma) or newer, fully compatible with Apple Silicon (M1/M2/M3/M4) and Intel Macs.

---

## 📄 License

MacAegis is free software. All operations run 100% locally on your Mac. Feel free to try it out and share your feedback!

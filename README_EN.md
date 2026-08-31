# MacAegis

<p align="left">
  <a href="README.md">简体中文</a> | <b>English</b>
</p>

<p align="center">
  <img src="docs/screenshots/vault_locked.png" width="850" alt="MacAegis Privacy Vault">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%2F%20Sequoia)-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-6.0%20Native-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/Size-2.4%20MB%20Ultra--light-success" alt="Size">
  <img src="https://img.shields.io/badge/Security-100%25%20Offline-emerald" alt="Security">
</p>

---

## Showcase

### 1. Privacy Vault
<p align="center">
  <img src="docs/screenshots/vault_folder.png" width="850" alt="Instant Folder Cloaking">
</p>

<p align="center">
  <img src="docs/screenshots/vault_files.png" width="850" alt="Multi-file Hidden List">
</p>

### 2. Smart Cleaner
<p align="center">
  <img src="docs/screenshots/dashboard.png" width="850" alt="Smart Cleaner Dashboard">
</p>

### 3. App Uninstaller
<p align="center">
  <img src="docs/screenshots/uninstaller.png" width="850" alt="App Uninstaller & Residue Cleanup">
</p>

### 4. Settings & System Monitoring
<p align="center">
  <img src="docs/screenshots/settings.png" width="600" alt="Preferences & Settings">
</p>

<p align="center">
  <img src="docs/screenshots/menubar.png" width="360" alt="Menu Bar Live Status Card">
</p>

---

## Core Features

* **Privacy Vault** — One-click hiding for files and folders, dual Touch ID / master password unlocking, with 64-character disaster recovery code support.
* **System Monitor** — Real-time display of CPU load, memory, fan speed, chip temperature, and upload/download speeds right in the menu bar.
* **History Cleaner** — Manage and purge system activity footprints to reduce privacy traces.

---

## MacAegis · Design Philosophy

Hiding files on macOS natively requires terminal commands—cumbersome and ungraceful.

What MacAegis does is straightforward: **put a cover over your files**.

* **No moving files, no reading or writing content, no encryption**—just toggling a filesystem attribute to make them vanish entirely from Finder and Spotlight.
* Whether it's a folder or individual files, selected via path or dragged straight into the vault, hiding and revealing are completed **instantaneously**.
* **Skipping encryption is a deliberate choice**. When encryption goes wrong, user data can suffer catastrophic loss; visual cloaking already solves 90% of everyday privacy needs—guarding against people casually browsing your Finder, not people trying to crack your physical drive.
* **100% offline**, no cloud syncing, no network calls, zero data collection. Your files remain exclusively on your own device from start to finish.

---

## Requirements & Installation

* Pure native Swift development, ultra-compact binary footprint (**2.4 MB**), gentle on memory and older hardware.
* Requires macOS 14.0 (Sonoma) or later. Primarily built for Apple Silicon (M-series chips).
* Download the latest `.dmg` release from [Releases](../../releases) and drag `MacAegis` into your `Applications` folder.

> **Note**: If macOS shows an "unidentified developer" or "damaged" dialog on first launch, execute this single command in Terminal to clear quarantine:
> ```bash
> xattr -cr /Applications/MacAegis.app
> ```
> (Or right-click the App -> select "Open" -> click "Open Anyway" in System Settings -> Privacy & Security)

---

Feel free to open an Issue or submit a Pull Request.


# MacAegis

<p align="left">
  <a href="README.md">简体中文</a> | <b>English</b>
</p>

A simple Mac utility built for personal everyday use. It mainly does two things: showing your network proxy routing status at a glance in the menu bar, and quickly hiding private files before sharing your screen, with a lightweight cache cleaner and uninstaller built in.

I originally wrote it for my own workflow. After polishing it for a bit, I decided to share it to see if anyone else finds it useful.

---

## What it does

### 1. Menu Bar Proxy Routing Status
When running proxy utilities, it's often hard to tell whether your connection is currently going direct or through a proxy. MacAegis displays real-time transfer speeds in the menu bar along with a status dot:
* Blue: Direct connection (no proxy).
* Green: Rule routing (smart split tunneling).
* Red: Global proxy active.

It reads network states directly from the macOS system layer, independent of whichever proxy client you use.

### 2. Fast File and Folder Concealment
When sharing your screen in meetings or lending your laptop, sensitive files in Finder can be accidentally seen:
* Drag and drop files or folders to hide them immediately from Finder. Spacebar QuickLook is also disabled.
* Operates in-place: large directories and video files hide instantly without waiting for file copying.
* Unlock quickly using Touch ID or your master password to reveal the file in Finder.
* Credentials are tied to macOS Keychain, so if you ever delete and reinstall the app, your locked items can be safely recognized and recovered.

### 3. Quick Cleaner & Uninstaller
* Easily cleans Xcode build caches (DerivedData), developer temporary files, logs, and browser caches.
* Drag and drop any `.app` to find and delete leftover configs across Library directories.

---

## Requirements & Installation

* Built natively in Swift. App size is ~3.5MB, memory footprint is ~20MB, and there are no background daemons.
* Requires macOS 14.0 (Sonoma) or later. Primarily built and optimized for Apple Silicon (M-series chips); not tested on Intel models.
* Download the latest build from Releases and move it to your Applications folder.

> **Note**: As an unsigned indie binary, if macOS shows a "damaged" or "unidentified developer" prompt on first launch, run this single line in Terminal to clear the quarantine attribute:
> ```bash
> xattr -cr /Applications/MacAegis.app
> ```
> (Or right-click the App -> select "Open" -> click "Open Anyway" in System Settings -> Privacy & Security)

---

If you run into issues or have ideas, feel free to open an issue.

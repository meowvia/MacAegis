# MacAegis

A lightweight, native macOS utility built for personal everyday use. Created to solve a few common Mac annoyances: **seeing your network routing/proxy status at a glance in the menu bar**, **instantly hiding private files before sharing your screen**, and **quickly cleaning up dev caches and leftover app files**.

Built 100% natively in Swift. Weighs only 3.5MB, uses ~20MB of RAM, has zero background daemons, and is completely free with no paywalls.

---

## 💡 What it does

### 1. Menu Bar Network Speed & Proxy Status
When running proxy tools, it's often confusing whether your current connection is going direct or through a proxy:
* Shows real-time upload and download speeds right in the macOS menu bar.
* Includes a simple status dot:
  * 🔵 **Blue**: Direct connection (no proxy).
  * 🟢 **Green**: Rule-based routing (smart split tunneling).
  * 🔴 **Red**: Global proxy active.
* Reads directly from macOS network states, independent of whichever proxy client you use.

### 2. Instant File/Folder Concealment (No More Screen-Sharing Awkwardness)
When sharing your screen in meetings or lending your laptop, sensitive contracts or personal photos in Finder can be accidentally visible:
* Drag and drop any file or folder to hide it immediately from Finder.
* Blocks QuickLook (spacebar preview) and standard app opening.
* Operates in-place: even a 100GB video or project directory is hidden in milliseconds with zero file copying.
* Unlock instantly with Touch ID or master password to reveal the file in Finder.
* Reclaiming resilience: even if the app is uninstalled, reinstalling automatically recognizes your keychain and lets you recover your files safely.

### 3. Quick Caches & Leftover Uninstaller
* Easily cleans Xcode build caches (`DerivedData`), developer artifacts, logs, and browser caches.
* Drag and drop any `.app` to discover and remove scattered leftover configs in `~/Library`.
* Unlike bulky cleaners, it uses virtually zero idle CPU and stays out of your way.

---

## 🛠️ Requirements & Build

* **macOS**: 14.0 (Sonoma) or later
* **Hardware**: Apple Silicon (M1/M2/M3/M4) & Intel Macs

```bash
# Build and run locally
git clone https://github.com/meowvia/MacAegis.git
cd MacAegis
swift build -c release
.build/arm64-apple-macosx/release/MacAegisApp
```

---

## ☕ Note & Feedback

This is an indie side project made for personal daily workflow. If you spot a bug or have an idea, feel free to open a discussion on [GitHub Issues](https://github.com/meowvia/MacAegis/issues)!

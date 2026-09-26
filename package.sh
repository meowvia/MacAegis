#!/bin/bash
set -e
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
echo "Compiling Swift Source..."
swift build -c release \
  -Xswiftc -plugin-path -Xswiftc /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins

echo "Building DMG..."
APP_NAME="MacAegis"
VERSION="v1.1.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
STAGING_DIR="dmg_staging"

# Cleanup
rm -rf "${APP_BUNDLE}" "${STAGING_DIR}"
rm -f "${APP_NAME}-${VERSION}.dmg"

# 1. Create App Bundle
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "${BUILD_DIR}/MacAegisApp" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
strip -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
if [ -f AppIcon.icns ]; then cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"; fi

cat <<PLIST > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.studio.macaegis</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSAppleEventsUsageDescription</key>
    <string>MacAegis 需要授权访达 (Finder) 权限，以便为您安全移除系统级受保护文件与应用。</string>
</dict>
</plist>
PLIST

# 2. Codesign (Ad-hoc)
codesign --force --deep -s - "${APP_BUNDLE}"

# 3. Create Staging Directory
mkdir -p "${STAGING_DIR}"
mv "${APP_BUNDLE}" "${STAGING_DIR}/"

# 3.1 Setup Liquid Glass DMG Custom Volume Icon
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "${STAGING_DIR}/.VolumeIcon.icns"
    SetFile -c icnC "${STAGING_DIR}/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "${STAGING_DIR}" 2>/dev/null || true
    SetFile -a V "${STAGING_DIR}/.VolumeIcon.icns" 2>/dev/null || true
fi

# 4. Add Applications symlink (Elegant Bilingual)
ln -s /Applications "${STAGING_DIR}/➡️ Drag to Install (拖拽至此安装)"

# 5. Add bilingual Installation & Permissions Guide
cat <<'GUIDE' > "${STAGING_DIR}/⚠️ 安装与权限指引 (Install & Permissions Guide).txt"
================================================================================
  MacAegis 安装与全盘访问权限配置指南 (Installation & Permissions Guide)
================================================================================

【关于代码签名与系统权限机制说明 / About Code Signing & macOS Security】
MacAegis 是一款完全免费、轻量且纯本地运行的开源工具。
由于本软件采用本地代码签名（Ad-Hoc 签名），未购买苹果付费开发者证书：
- macOS 的安全机制 (TCC) 是根据应用每次编译的唯一代码哈希 (CDHash) 绑定权限的。
- 当您覆盖更新或重新安装新版本后，macOS 系统设置中即使仍然显示 MacAegis 已勾选，
  但底层授权已与新版本二进制脱节，导致完全磁盘访问权限在实际运行中静默失效（无法扫描受保护目录）。

--------------------------------------------------------------------------------
【推荐安装与更新步骤 / Recommended Installation & Update Steps】

【方案 A：重装或覆盖升级用户（强烈推荐）】
1. 双击运行当前窗口内的「Update Assistant (更新助手).command」：
   - 助手会自动退出旧版进程、重置系统启动缓存、拷贝新版本至「应用程序」并移除隔离属性。
2. 重置「完全磁盘访问权限」：
   - 打开 macOS【系统设置】 (System Settings) ->【隐私与安全性】 (Privacy & Security) ->【完全磁盘访问权限】 (Full Disk Access)。
   - 在列表中找到旧的「MacAegis」，点击下方的减号【-】将其彻底移除。
   - 点击加号【+】，导航至【应用程序】(Applications) 重新选择「MacAegis.app」并开启授权。
   * 提示：必须先移除旧授权再重新添加，单纯关闭再打开开关无法更新系统的代码签名凭据！

【方案 B：全新首次安装用户】
1. 将「MacAegis」拖拽至「➡️ Drag to Install (拖拽至此安装)」软链接即可完成安装。
2. 初次打开应用时，前往【系统设置】->【隐私与安全性】->【完全磁盘访问权限】，将 MacAegis 添加并开启。

================================================================================
  [English Version]
================================================================================
【About Ad-Hoc Signing & macOS TCC Permissions】
MacAegis is an open-source, purely local utility. It uses an Ad-Hoc code signature.
Under macOS TCC security architecture, permissions are strictly bound to the 
unique binary CDHash of each build. When replacing or updating MacAegis, the 
previous Full Disk Access (FDA) authorization becomes invalidated by macOS, even
if the toggle appears enabled in System Settings.

【Recommended Update Workflow】
1. Run "Update Assistant (更新助手).command":
   - It terminates older instances, updates the application in /Applications, 
     and clears quarantine flags automatically.
2. Reset Full Disk Access:
   - Go to macOS [System Settings] -> [Privacy & Security] -> [Full Disk Access].
   - Select the existing "MacAegis" entry and click the minus [-] button to remove it.
   - Click the plus [+] button, select /Applications/MacAegis.app, and enable the toggle.
   * Note: Removing [-] and re-adding [+] is required for macOS to bind to the new signature.

【First-Time Installation】
1. Drag "MacAegis" to "➡️ Drag to Install (拖拽至此安装)".
2. Launch the app and grant Full Disk Access in System Settings > Privacy & Security.
================================================================================
GUIDE

# 6. Add robust one-click installer & update assistant (Elegant Bilingual)
cat <<'SCRIPT' > "${STAGING_DIR}/Update Assistant (更新助手).command"
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="MacAegis.app"
DEST="/Applications/${APP_NAME}"

echo "========================================================"
echo "  MacAegis One-Click Update Utility                     "
echo "  MacAegis 一键覆盖更新与权限重置助手                    "
echo "========================================================"
echo ""

echo "[1/5] Force killing old processes... (正在退出旧版本进程)"
osascript -e 'tell application id "com.studio.macaegis" to quit' 2>/dev/null || true
sleep 1.5
launchctl bootout gui/$(id -u)/com.studio.macaegis 2>/dev/null || true
killall -9 MacAegis 2>/dev/null || true
sleep 0.5

if [ -d "$DEST" ]; then
    echo "[2/5] Removing older version... (正在移除旧版本应用)"
    rm -rf "$DEST" 2>/dev/null || true
fi

echo "[3/5] Resetting LaunchServices cache... (正在重置系统注册缓存)"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$DEST" 2>/dev/null || true

echo "[4/5] Copying new version to /Applications... (正在安装新版本至应用程序目录)"
cp -R "${DIR}/${APP_NAME}" "/Applications/"

echo "[5/5] Clearing quarantine attributes... (移除隔离属性以解除 macOS 安全拦截)"
xattr -cr "$DEST" 2>/dev/null || true

echo ""
echo "========================================================"
echo "  ⚠️  【必须执行：全盘访问权限重置 / Full Disk Access】"
echo "========================================================"
echo "由于 MacAegis 使用开源本地自签名，新版本二进制的代码哈希 (CDHash) 已变更。"
echo "若不重置权限，macOS 底层将静默拒绝深度扫描与清理！"
echo ""
echo "👉 请在即将弹出的【完全磁盘访问权限】窗口中执行以下 2 步："
echo "   1. 选中旧的「MacAegis」，点击列表下方的减号【-】将其移除；"
echo "   2. 点击加号【+】，选择 /Applications/MacAegis.app 重新添加并开启授权。"
echo ""
echo "English:"
echo "Due to Ad-Hoc signing, the binary CDHash has changed."
echo "Please remove the old MacAegis entry [-] in Full Disk Access and re-add [+]."
echo "========================================================"
echo ""

echo "🚀 Opening System Settings > Full Disk Access... (正在打开权限设置)"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" 2>/dev/null || true
sleep 1

echo "🚀 Launching new MacAegis... (正在启动新版 MacAegis)"
open "$DEST"

echo ""
echo "✅ 更新流程完成！(Update finished!)"
(sleep 1.2 && osascript -e 'tell application "Terminal" to close (every window whose name contains "Update Assistant")' 2>/dev/null &) &
exit 0
SCRIPT
chmod +x "${STAGING_DIR}/Update Assistant (更新助手).command"

# 5.1 Deep Clean Staging (Remove AppleDouble, DS_Store, and Temporary Cruft)
find "${STAGING_DIR}" -name ".DS_Store" -delete 2>/dev/null || true
find "${STAGING_DIR}" -name "._*" -delete 2>/dev/null || true
find "${STAGING_DIR}" -name "*~" -delete 2>/dev/null || true

# 6. Create Ultra-Lightweight DMG (Apple Native ULMO LZMA)
hdiutil info | grep "/Volumes/${APP_NAME}" | awk '{print $1}' | while read -r dev; do
    hdiutil detach "$dev" -force 2>/dev/null || true
done
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format ULMO "${APP_NAME}-${VERSION}.dmg"
cp -f "${APP_NAME}-${VERSION}.dmg" ~/Desktop/

# Cleanup
rm -rf "${STAGING_DIR}"
echo "Done! Saved to Desktop."

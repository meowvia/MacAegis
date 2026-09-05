#!/bin/bash
set -e
echo "Compiling Swift Source..."
swift build -c release

echo "Building DMG..."
APP_NAME="MacAegis"
VERSION="v0.2.1-beta"
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
    <string>0.2.1</string>
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

# 4. Add Applications symlink (Elegant Bilingual)
ln -s /Applications "${STAGING_DIR}/➡️ Drag to Install (拖拽至此安装)"

# 5. Add robust one-click installer (Elegant Bilingual)
cat <<'SCRIPT' > "${STAGING_DIR}/Update Assistant (更新助手).command"
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="MacAegis.app"
DEST="/Applications/${APP_NAME}"

echo "======================================"
echo "  MacAegis One-Click Update Utility   "
echo "      MacAegis 一键覆盖更新程序       "
echo "======================================"
echo ""

echo "[1/4] Force killing old processes... (正在强制关闭旧版本进程)"
# Use killall with signal 9 to ensure no zombies are left
# 1. First, gracefully ask it to quit to unregister any launchd/SMAppService hooks
osascript -e 'tell application id "com.studio.macaegis" to quit' 2>/dev/null || true
sleep 1.5

# 2. Unregister launchd service manually to prevent macOS zombie resurrection
launchctl bootout gui/$(id -u)/com.studio.macaegis 2>/dev/null || true

# 3. Now forcefully kill any remaining stubborn processes
killall -9 MacAegis 2>/dev/null || true
sleep 0.5
# Also kill by bundle ID just in case
osascript -e 'tell application id "com.studio.macaegis" to quit' 2>/dev/null || true
sleep 1

if [ -d "$DEST" ]; then
    echo "[2/4] Found older version, deep removing... (发现旧版本，正在深度移除)"
    # First try normal rm
    rm -rf "$DEST" 2>/dev/null || true
    
    # If it still exists (permission denied), prompt for admin privileges via AppleScript
    if [ -d "$DEST" ]; then
        echo "--> Permission required to clear old version... (需要授权以彻底清除旧版本)"
        osascript -e "do shell script \"rm -rf '$DEST'\" with administrator privileges"
    fi
fi

echo "[3/4] Copying new version to /Applications... (正在复制新版本至应用程序)"
cp -R "${DIR}/${APP_NAME}" "/Applications/"

echo "[4/4] Clearing quarantine attributes... (清理隔离属性以解除系统拦截)"
xattr -cr "$DEST" 2>/dev/null || true

echo "--------------------------------------"
echo "✅ Update completed successfully! (更新已成功完成)"
echo "🚀 Launching MacAegis... (正在拉起新版 MacAegis)"
open "$DEST"

# Auto-close the Terminal window that executed this command
osascript -e 'tell application "Terminal" to close first window' & exit 0
SCRIPT
chmod +x "${STAGING_DIR}/Update Assistant (更新助手).command"

# 6. Create DMG
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${APP_NAME}-${VERSION}.dmg"
cp "${APP_NAME}-${VERSION}.dmg" ~/Desktop/

# Cleanup
rm -rf "${STAGING_DIR}"
echo "Done! Saved to Desktop."

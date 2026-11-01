#!/bin/zsh
# Builds RFBattery.app (menu-bar only) into ./build
set -euo pipefail
cd "${0:A:h}"

swift build -c release
APP=build/RFBattery.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RFBattery "$APP/Contents/MacOS/RFBattery"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>RFBattery</string>
    <key>CFBundleIdentifier</key><string>com.vd.rfbattery</string>
    <key>CFBundleExecutable</key><string>RFBattery</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $APP"

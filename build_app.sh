#!/bin/zsh
# Builds a universal (arm64 + x86_64) RFBattery.app (menu-bar only) into ./build
# Optional: VERSION=1.2.3 ./build_app.sh   ZIP=1 also produces build/RFBattery.zip
set -euo pipefail
cd "${0:A:h}"

VERSION="${VERSION:-0.1}"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/RFBattery"

APP=build/RFBattery.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/RFBattery"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>RFBattery</string>
    <key>CFBundleIdentifier</key><string>com.vd.rfbattery</string>
    <key>CFBundleExecutable</key><string>RFBattery</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/RFBattery"))"

if [[ "${ZIP:-0}" == 1 ]]; then
    rm -f build/RFBattery.zip
    ditto -c -k --keepParent "$APP" build/RFBattery.zip
    echo "Packed build/RFBattery.zip"
fi

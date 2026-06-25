#!/usr/bin/env bash
# Assemble a double-clickable TickTalk.app from the SwiftPM debug build.
# This is a DEV preview bundle — no code signing / entitlements / notarization.
# The real distributable app target lands at the packaging milestone.
set -euo pipefail

cd "$(dirname "$0")/.."          # macos/TickTalk
CONFIG="${1:-debug}"

swift build -c "$CONFIG"
BIN=".build/$CONFIG/TickTalk"
APP=".build/TickTalk.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/TickTalk"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>TickTalk</string>
  <key>CFBundleIdentifier</key><string>io.github.lotus2077.ticktalk</string>
  <key>CFBundleName</key><string>TickTalk</string>
  <key>CFBundleDisplayName</key><string>TickTalk</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# App icon — TickTalk "T-Burst" (.icns built from macos/branding/icon).
mkdir -p "$APP/Contents/Resources"
ICNS="../branding/icon/TickTalk.icns"
if [ -f "$ICNS" ]; then
    cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
    echo "Bundled app icon: $ICNS"
else
    echo "warning: $ICNS not found — building without an app icon"
fi

# Menu-bar template icon (the monochrome burst, recolored by macOS).
MENUBAR="../branding/icon/TickTalk-menubar.png"
if [ -f "$MENUBAR" ]; then
    cp "$MENUBAR" "$APP/Contents/Resources/TickTalk-menubar.png"
    echo "Bundled menu-bar icon: $MENUBAR"
fi

# Sign with the stable self-signed "TickTalk Dev" identity when present, so
# the code identity (and its Keychain item ACLs) stay constant across rebuilds —
# no repeated keychain prompts. Run scripts/dev-signing-setup.sh to create it.
# Falls back to ad-hoc (which re-prompts each rebuild). The real Xcode target
# uses a Developer ID instead.
IDENTITY="TickTalk Dev"
if security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    security unlock-keychain -p ticktalk-dev ticktalk-codesign.keychain-db 2>/dev/null || true
    codesign --force --deep --sign "$IDENTITY" "$APP" 2>/dev/null
    echo "Built $APP (signed: $IDENTITY)"
else
    codesign --force --deep --sign - "$APP" 2>/dev/null
    echo "Built $APP (ad-hoc; run scripts/dev-signing-setup.sh for a stable identity)"
fi

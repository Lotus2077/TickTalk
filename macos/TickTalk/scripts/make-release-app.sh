#!/usr/bin/env bash
# Assemble a distributable, ad-hoc-signed TickTalk.app (release build) with the
# engine Docker image + the standalone dist compose bundled inside, so the app
# runs after a plain .dmg install with no source repo present. No Apple
# Developer ID / notarization — users bypass Gatekeeper on first open
# (right-click -> Open, or `xattr -cr`; see the release notes). Apple Silicon.
set -euo pipefail

cd "$(dirname "$0")/.."          # macos/TickTalk
REPO_ROOT="$(cd ../.. && pwd)"

# 1. Ensure the engine image tar exists (build + save it if missing).
TAR="$REPO_ROOT/macos/TickTalk/.build/engine-image.tar.gz"
if [ ! -f "$TAR" ]; then
    echo "engine-image.tar.gz missing — running build-and-save-image.sh …"
    bash "$REPO_ROOT/packaging/build-and-save-image.sh"
fi

# 2. Release build.
swift build -c release
BIN=".build/release/TickTalk"
APP=".build/TickTalk.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/TickTalk"

# 3. Info.plist (v0.1.0; matches the preview bundle).
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

# 4. Resources: icon + menu-bar template + engine image tar + dist compose.
#    Resource basenames are exact so DockerBackendController finds them via
#    Bundle.main: "engine-image.tar.gz" (bundledImageTar) and
#    "docker-compose.yml" (findComposeFile, which beats the dev walk-up).
ICNS="../branding/icon/TickTalk.icns"
if [ -f "$ICNS" ]; then
    cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
else
    echo "warning: $ICNS not found — building without an app icon"
fi
MENUBAR="../branding/icon/TickTalk-menubar.png"
[ -f "$MENUBAR" ] && cp "$MENUBAR" "$APP/Contents/Resources/TickTalk-menubar.png"

cp "$TAR" "$APP/Contents/Resources/engine-image.tar.gz"
cp "$REPO_ROOT/packaging/docker-compose.dist.yml" "$APP/Contents/Resources/docker-compose.yml"

# 5. Sign LAST — after every resource is in place. Copying anything into the
#    bundle after codesign invalidates the seal (even right-click->Open fails).
#    Ad-hoc (no Developer ID); the real Xcode target would use a Developer ID.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "Built $APP (ad-hoc signed, release; engine tar + dist compose bundled)"
du -sh "$APP"

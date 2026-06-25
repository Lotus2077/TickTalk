#!/usr/bin/env bash
# Build the distributable TickTalk-0.1.0-arm64.dmg from the release .app, using
# only built-in hdiutil (no create-dmg dependency). Drag-to-install layout
# (TickTalk.app + an /Applications symlink). Output lands under .build/
# (gitignored). Run from anywhere; paths resolve relative to this script.
set -euo pipefail

cd "$(dirname "$0")/.."          # repo root
VERSION="0.1.0"
APP="macos/TickTalk/.build/TickTalk.app"
DMG="macos/TickTalk/.build/TickTalk-${VERSION}-arm64.dmg"

# Build the .app if it isn't there yet.
[ -d "$APP" ] || bash macos/TickTalk/scripts/make-release-app.sh

# Stage: the .app + an /Applications symlink for drag-install.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/TickTalk.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create \
    -volname "TickTalk" \
    -srcfolder "$STAGE" \
    -ov -format UDZO \
    "$DMG"

echo "Built $DMG"
ls -lh "$DMG"

#!/usr/bin/env bash
set -euo pipefail

APP_NAME="McAudio"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$(dirname "$0")/../Info.plist")
VOLUME_NAME="McAudio ${VERSION}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
BUNDLE="$DIST/${APP_NAME}.app"
DMG_FINAL="$DIST/${APP_NAME}-${VERSION}.dmg"
DMG_TEMP="$DIST/${APP_NAME}-tmp.dmg"
STAGING="$DIST/dmg-staging"

cd "$ROOT"

# ── 1. build ─────────────────────────────────────────────────────────────────
echo "→ Building release binary..."
swift build -c release --arch arm64

# ── 2. assemble .app bundle ───────────────────────────────────────────────────
echo "→ Assembling .app bundle..."
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"
cp ".build/release/$APP_NAME" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp "Info.plist"               "$BUNDLE/Contents/Info.plist"
codesign --force --sign - "$BUNDLE" 2>/dev/null || true

# ── 3. stage DMG contents ─────────────────────────────────────────────────────
echo "→ Staging DMG contents..."
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -r "$BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# ── 4. create writable DMG ───────────────────────────────────────────────────
echo "→ Creating DMG..."
rm -f "$DMG_TEMP" "$DMG_FINAL"

# Size: app + 10 MB headroom for Finder metadata
APP_SIZE_KB=$(du -sk "$STAGING" | cut -f1)
DMG_SIZE_KB=$(( APP_SIZE_KB + 10240 ))

hdiutil create \
    -srcfolder "$STAGING" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=16,a=16,b=16" \
    -format UDRW \
    -size ${DMG_SIZE_KB}k \
    "$DMG_TEMP"

# ── 5. mount and configure Finder window layout ───────────────────────────────
echo "→ Configuring DMG window layout..."
hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" -quiet
MOUNT_DIR="/Volumes/${VOLUME_NAME}"

# Give Finder a moment to register the volume
sleep 2

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 760, 440}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set position of item "${APP_NAME}.app" of container window to {160, 170}
        set position of item "Applications"    of container window to {400, 170}
        update without registering applications
        delay 3
        close
    end tell
end tell
APPLESCRIPT

sync
sleep 2
chmod -Rf go-w "$MOUNT_DIR"

hdiutil detach "$MOUNT_DIR" -force -quiet

# ── 6. convert to compressed read-only DMG ───────────────────────────────────
echo "→ Compressing DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

# ── 7. clean up ───────────────────────────────────────────────────────────────
rm -f "$DMG_TEMP"
rm -rf "$STAGING"

echo ""
echo "✓ ${APP_NAME}.app  →  $BUNDLE"
echo "✓ DMG              →  $DMG_FINAL ($(du -sh "$DMG_FINAL" | cut -f1))"

#!/usr/bin/env bash
# Packages build/Wakey.app into build/Wakey-<version>.dmg (drag-to-Applications layout).
# Usage: scripts/make-dmg.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
[[ -d build/Wakey.app ]] || scripts/build-app.sh "$VERSION"

STAGE="$(mktemp -d)"
cp -R build/Wakey.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
DMG="build/Wakey-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Wakey" -srcfolder "$STAGE" -ov -format UDZO "$DMG" > /dev/null
rm -rf "$STAGE"

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ { print $2; exit }')}"
if [[ -n "$IDENTITY" && "$IDENTITY" != "-" ]]; then
  codesign --timestamp --sign "$IDENTITY" "$DMG"
fi
echo "Created $DMG"

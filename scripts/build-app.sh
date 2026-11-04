#!/usr/bin/env bash
# Builds build/Wakey.app from the Swift package and signs it.
# Usage: scripts/build-app.sh [version]
#   UNIVERSAL=1      build arm64 + x86_64
#   CONFIG=debug     debug build (default: release)
#   SIGN_IDENTITY=…  "Developer ID Application: Name (TEAMID)", or "-" for ad hoc.
#                    Default: the first Developer ID Application identity in the
#                    keychain, else ad hoc.
#
# Lid mode needs a Developer ID signature: macOS only runs the privileged
# helper when the app and helper are signed by the same team.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
BUILD="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
CONFIG="${CONFIG:-release}"
ARCHS=(--arch arm64)
[[ "${UNIVERSAL:-0}" == "1" ]] && ARCHS=(--arch arm64 --arch x86_64)

swift build -c "$CONFIG" "${ARCHS[@]}"
BIN="$(swift build -c "$CONFIG" "${ARCHS[@]}" --show-bin-path)"

APP=build/Wakey.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchDaemons"

cp "$BIN/Wakey" "$APP/Contents/MacOS/Wakey"
cp "$BIN/WakeyHelper" "$APP/Contents/MacOS/WakeyHelper"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Support/Info.plist > "$APP/Contents/Info.plist"
cp Support/app.wakey.Wakey.helper.plist "$APP/Contents/Library/LaunchDaemons/"
cp README.md README.ko.md README.ja.md CHANGELOG.md "$APP/Contents/Resources/"
cp assets/icon-rounded.png "$APP/Contents/Resources/WakeyIcon.png"

# assets/AppIcon.png and icon-rounded.png come from scripts/make-icon.swift.
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" assets/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" assets/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ { print $2; exit }')}"
[[ -n "$IDENTITY" ]] || IDENTITY="-"
if [[ "$IDENTITY" == "-" ]]; then
  TIMESTAMP=(--timestamp=none)   # ad hoc, local use only
else
  TIMESTAMP=(--timestamp)        # hardened runtime + secure timestamp, both required for notarization
fi

codesign --force --options runtime "${TIMESTAMP[@]}" \
  --identifier app.wakey.Wakey.helper --sign "$IDENTITY" "$APP/Contents/MacOS/WakeyHelper"
codesign --force --options runtime "${TIMESTAMP[@]}" --sign "$IDENTITY" "$APP"

echo "Built $APP ($VERSION, build $BUILD)"
echo "Signed with: $IDENTITY"

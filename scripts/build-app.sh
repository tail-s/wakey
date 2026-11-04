#!/bin/sh
# Builds build/Wakey.app from the Swift package and signs it.
#
#   scripts/build-app.sh            release build, signed with the first
#                                   "Developer ID Application" identity, or ad hoc
#   CONFIG=debug scripts/build-app.sh
#   WAKEY_SIGN_IDENTITY="-" scripts/build-app.sh   force ad hoc signing
#
# Lid mode needs a real signing identity: macOS only runs the privileged
# helper when the app and helper are signed by the same team.
set -eu

cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
APP="build/Wakey.app"

swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchDaemons"

cp "$BIN/Wakey" "$APP/Contents/MacOS/Wakey"
cp "$BIN/WakeyHelper" "$APP/Contents/MacOS/WakeyHelper"
cp Support/Info.plist "$APP/Contents/Info.plist"
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

IDENTITY="${WAKEY_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ { print $2; exit }')}"
[ -n "$IDENTITY" ] || IDENTITY="-"

codesign --force --options runtime --timestamp=none \
  --identifier app.wakey.Wakey.helper --sign "$IDENTITY" "$APP/Contents/MacOS/WakeyHelper"
codesign --force --options runtime --timestamp=none \
  --sign "$IDENTITY" "$APP"

echo "Built $APP"
echo "Signed with: $IDENTITY"

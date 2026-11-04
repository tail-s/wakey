#!/usr/bin/env bash
# Notarizes and staples build/Wakey-<version>.dmg (built with a Developer ID signature).
# Usage: scripts/notarize.sh [version]
#
# Credentials, either:
#   NOTARY_PROFILE=wakey    a keychain profile made once with
#                           `xcrun notarytool store-credentials wakey` (default)
#   or App Store Connect API key (used by CI):
#   NOTARY_KEY_PATH=AuthKey_XXXX.p8  NOTARY_KEY_ID=XXXX  NOTARY_ISSUER_ID=uuid
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
DMG="build/Wakey-$VERSION.dmg"
[[ -f "$DMG" ]] || { echo "Missing $DMG — run scripts/make-dmg.sh $VERSION with a Developer ID signature first."; exit 1; }

if [[ -n "${NOTARY_KEY_PATH:-}" ]]; then
  CREDS=(--key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
else
  CREDS=(--keychain-profile "${NOTARY_PROFILE:-wakey}")
fi

xcrun notarytool submit "$DMG" "${CREDS[@]}" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"
echo "Notarized $DMG"

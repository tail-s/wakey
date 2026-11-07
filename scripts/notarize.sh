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

# Stapling fetches the ticket from Apple's servers, and that connection sometimes drops
# ("The network connection was lost", error 68). Retry instead of failing the release.
ATTEMPTS=5
for attempt in $(seq 1 "$ATTEMPTS"); do
  if xcrun stapler staple "$DMG"; then break; fi
  if (( attempt == ATTEMPTS )); then echo "Stapling failed $ATTEMPTS times; giving up."; exit 1; fi
  delay=$(( attempt * ${STAPLE_RETRY_DELAY:-15} ))
  echo "Stapling failed (attempt $attempt of $ATTEMPTS); retrying in ${delay}s…"
  sleep "$delay"
done
spctl --assess --type open --context context:primary-signature -v "$DMG"
echo "Notarized $DMG"

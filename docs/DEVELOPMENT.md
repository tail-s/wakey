# Developing Wakey

## Build and run

Requires Xcode 16 or later (Swift 6) on macOS 13+.

```bash
swift test                                              # unit tests: engine, translations, Claude Code hooks
scripts/build-app.sh 0.1.0                              # → build/Wakey.app   (UNIVERSAL=1 for arm64 + x86_64)
open build/Wakey.app
scripts/make-dmg.sh 0.1.0                               # → build/Wakey-0.1.0.dmg
build/Wakey.app/Contents/MacOS/Wakey --status           # print what Wakey detects and decides; changes nothing
build/Wakey.app/Contents/MacOS/Wakey --snapshot /tmp/s  # render the menu and Settings in every language to PNGs
swift scripts/make-icon.swift assets/icon.png assets    # regenerate assets/AppIcon.png and icon-rounded.png
```

`build-app.sh` signs with the first "Developer ID Application" identity in your keychain, or ad hoc if there is none.
Set `SIGN_IDENTITY` to pick one, or `SIGN_IDENTITY=-` for ad hoc. Lid mode only works in a Developer ID build:
macOS runs the privileged helper only when the app and helper are signed by the same team.

To try lid mode from a local build, move `Wakey.app` to Applications, open **Settings › General › Lid mode ›
Install…**, and allow Wakey in **System Settings › General › Login Items & Extensions**.

## Project layout

```
Sources/WakeyCore/      pure logic shared by everything
  Engine.swift            decides sleep block / screen on / lid mode from the inputs
  L10n.swift              UI strings (en / ko / ja)
  ClaudeHooks.swift       adds and removes Wakey's hooks in ~/.claude/settings.json
  HelperProtocol.swift    XPC interface of the helper
Sources/Wakey/          menu bar app
  AppModel.swift          preferences, polling, applying the engine's decision
  System/                 lid, displays, power, power assertions, lid mode helper client, login item
  Detection/              AI app detection, Claude Code hook installer
  UI/                     menu panel, Settings window, icons, snapshot mode
Sources/WakeyHelper/    privileged helper (SMAppService daemon) that runs `pmset -a disablesleep`
Support/                Info.plist and the helper's launchd plist
scripts/                build, DMG, notarization and icon scripts
```

- **Add a UI language:** add a case to `AppLanguage` and a table in `L10n.swift`. The tests fail if a key is missing.
- **Change when Wakey keeps the Mac awake:** edit `Engine.decide` and add a case to `EngineTests`.

## Releasing

1. Move the `[Unreleased]` notes in [CHANGELOG.md](../CHANGELOG.md) under a new version heading, for example
   `## [0.2.0] - 2026-12-01`. That section becomes the GitHub release notes.
2. Update the "What's new" line in all three READMEs.
3. Commit, then tag and push: `git tag -a v0.2.0 -m "Wakey 0.2.0" && git push origin main v0.2.0`.

Pushing a tag such as `v0.2.0` makes GitHub Actions ([build.yml](../.github/workflows/build.yml)) run the tests, build a
universal DMG, sign it with Developer ID, notarize it, and publish a GitHub release. Pushes to `main` and pull
requests only test and build. Signing and notarization run only when these repository secrets exist
(Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `MACOS_CERT_P12` | Developer ID Application certificate + private key exported as .p12, then `base64 -i cert.p12` |
| `MACOS_CERT_PASSWORD` | the password chosen when exporting the .p12 |
| `NOTARY_KEY_P8` | App Store Connect API key (Users and Access → Integrations), `base64 -i AuthKey_XXXX.p8` |
| `NOTARY_KEY_ID` | that key's ID |
| `NOTARY_ISSUER_ID` | the issuer ID shown above the keys list |

To sign and notarize locally instead:

```bash
xcrun notarytool store-credentials wakey   # once; asks for Apple ID, team ID, app-specific password
scripts/build-app.sh 0.1.0 && scripts/make-dmg.sh 0.1.0
scripts/notarize.sh 0.1.0
```

### Opening a build that isn't notarized

Local builds and CI artifacts from branch pushes aren't notarized. Open one via **System Settings → Privacy & Security →
Open Anyway**, or run `xattr -dr com.apple.quarantine /Applications/Wakey.app`.

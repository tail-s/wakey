# Changelog

All notable changes to Wakey are listed here, newest first.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-05

The first release.

### Added

- **Stay awake while AI works.** One switch keeps your Mac awake only while Claude, ChatGPT (Codex), Antigravity or terminal agents are working, and lets it sleep when they're done.
- **Automatic protection.** Wakey checks the lid, external display, power and temperature, and blocks only the sleep that would stop your AI. The screen still turns off and locks as usual.
- **Lid mode.** Keeps going with the lid closed, even with no display or power. In clamshell mode it turns on by itself, so turning off the monitor won't put the Mac to sleep. Needs a one-time approval in System Settings.
- **Stay awake between tasks**, for remote access such as controlling Claude from your phone.
- **Timer** (30 min, 1 hr, 2 hr or always) and **Turn off screen and step away**.
- **Keep on battery**, with a battery floor of 10%, 20% or 30%.
- **Advanced** switches: Prevent sleep, Keep screen on, Stay awake with lid closed.
- **Claude Code signals.** Optional hooks for exact start and finish detection, added from Settings with a backup of your settings file.
- **Safety.** Lid mode turns off by itself when Wakey quits or crashes, when the Mac gets hot, or at your battery floor.
- **English, Korean and Japanese**, and **System, Light and Dark** appearance, all switchable in Settings.

### Known limitations

- Lid mode hasn't been tested on many Macs yet. The first time you close the lid with it on, check that the Mac doesn't get too warm.
- Antigravity work is estimated from activity, so very short tasks may be missed.

### For developers

- Build from source with `scripts/build-app.sh`. Pushing a `v*` tag builds, signs, notarizes and publishes a release with GitHub Actions.

## Version plan

These versions are planned and may change.

### 0.2.0 — Better feedback

- Notifications when Wakey lets the Mac sleep: battery floor, heat, or timer.
- The menu bar icon shows the time left on the timer.
- Turn-finished signals from the Codex command-line tool.

### 0.3.0 — Convenience

- Automatic updates.
- A keyboard shortcut to turn auto mode on and off.
- Actions for the Shortcuts app.

### 1.0.0 — Stable

- Settings and behavior are considered stable.
- Documentation covers every setting in all three languages.

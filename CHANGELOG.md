# Changelog

All notable changes to Wakey are listed here, newest first.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

Nothing has been released yet.

## [Unreleased]

Work in progress toward **0.1.0**. Everything planned for 0.1.0 below is built and runs from source.

### Added

- Menu bar app (Swift, SwiftUI) with the auto mode panel: one switch, lid section, timer, status, advanced toggles.
- Settings window with General, Detection and About tabs.
- Decision engine that picks sleep block and lid mode from the lid, external display, power, heat and AI activity.
- Sleep block and Keep screen on through macOS power assertions.
- Lid mode through a privileged helper (SMAppService daemon over XPC). The helper turns lid mode off when Wakey quits or crashes.
- AI detection: Claude and ChatGPT/Codex app signals, Claude Code hooks (added from Settings, with a backup of `~/.claude/settings.json`), Antigravity and terminal agents from CPU activity.
- English, Korean and Japanese, switchable in Settings without restarting.
- System, Light and Dark appearance.
- `--status` and `--snapshot` command-line options for checking the app without changing anything.
- Build script that assembles and signs `Wakey.app` (optionally universal), plus DMG, notarization and icon scripts.
- GitHub Actions workflow: tests and builds a DMG on every push; on a `v*` tag it also signs, notarizes and publishes a GitHub Release with this changelog's notes.
- Unit tests for the decision engine, translations and Claude Code hook editing.
- README in English, Korean and Japanese.

### Not yet tested

- Installing and approving the lid mode helper, and lid mode with the lid actually closed.
- Launch at login from a copy in the Applications folder.
- Notarization for distribution.

---

## Version plan

These versions are planned and may change.

### 0.1.0 — First release

The first version you can install. The goal: turn on one switch and never think about sleep settings again.

#### Added

- **Auto mode.** "Stay awake while AI works" picks the right protection from your lid, monitor, and power.
- **Sleep block (stage 4).** Keeps the Mac awake while the screen turns off and locks.
- **Lid mode (stage 5).** Keeps the Mac awake with the lid closed. Needs an admin password once to install a helper.
- **Clamshell detection.** Turns on lid mode by itself, so turning off the monitor won't sleep the Mac.
- **AI detection.** Claude Code (start and finish signals), ChatGPT/Codex and the Claude app (app signals), Antigravity (estimated from activity), and terminal agents.
- **Stay awake between tasks**, for remote access.
- **Timer**: 30 min, 1 hr, 2 hr, or until turned off.
- **Turn off screen and step away.**
- **Keep on battery**, with a battery floor of 10%, 20%, or 30%.
- **Advanced** manual toggles: Prevent sleep, Keep screen on, Stay awake with lid closed.
- **Safety.** Lid mode turns off when Wakey quits or crashes, when the Mac gets hot, or when the battery reaches the floor.
- **Languages**: English (default), Korean, Japanese.
- **Appearance**: System, Light, Dark.
- **Launch at login.**

### 0.2.0 — Better feedback

#### Added

- Notifications when Wakey lets the Mac sleep: battery floor, heat, or timer.
- The menu bar icon shows the time left on the timer.
- Turn-finished signals from the Codex command-line tool.

### 0.3.0 — Convenience

#### Added

- Automatic updates.
- A keyboard shortcut to turn auto mode on and off.
- Actions for the Shortcuts app.

### 1.0.0 — Stable

#### Changed

- Settings and behavior are considered stable.
- Documentation covers every setting in all three languages.

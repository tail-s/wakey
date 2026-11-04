<p align="center">
  <img src="assets/icon-rounded.png" width="128" alt="Wakey icon">
</p>

<h1 align="center">Wakey</h1>

<p align="center">
  <b>Keeps your Mac awake while AI works, and lets it sleep when the work is done.</b><br>
  English · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a>
</p>

> **[Download Wakey 0.1.0](https://github.com/tail-s/wakey/releases/latest)** · macOS 13 or later · Apple silicon and Intel

---

## Why Wakey?

AI agents like **Claude Code**, **Codex**, and **Antigravity** run on your Mac. If your Mac falls asleep, they stop in the middle of a task.

macOS has many sleep settings: screen saver, display off, lock, sleep, lid close, and more. It's hard to tell which of them actually stops your AI.

Wakey keeps it simple: **turn on one switch**. Wakey checks your lid, monitor, and power, and blocks only the sleep that would stop your AI.

---

## How your Mac falls asleep

When you stop using your Mac, it goes through these stages. **Only stage 4 and later stop your AI.**

| Stage | What happens | Does AI keep working? | Wakey |
|---|---|---|---|
| 1. Screen saver | A screen saver starts after a few idle minutes | Yes | – |
| 2. Display off | The screen goes dark | Yes | – |
| 3. Lock | You need your password to get back in | Yes | Left alone, for your security |
| **4. Idle sleep** | The whole Mac sleeps because no one is using it | **No, it stops** | **Blocks it** |
| **5. Lid closed** | Closing the lid, or turning off the monitor in clamshell mode, sleeps the Mac at once | **No, it stops** | **Blocks it** (Lid mode) |
| 6. Manual sleep | You choose Sleep from the Apple menu | No, it stops | Lid mode blocks this too |
| 7. Low battery | The battery is almost empty | No, it stops | Can't be blocked. Wakey lets go early, at a level you choose |
| 8. Deep sleep | After a long sleep, memory is saved to disk | No, it stops | Never reached when stages 4–6 are blocked |

**In short:** stages 1–3 only affect the screen, so your AI keeps working. **Wakey controls stages 4 and 5.**

> **Tip:** Your Mac can't idle-sleep while the screen is on. So in practice, the "Turn display off" timer in System Settings is also when your Mac goes to sleep.

---

## What Wakey does

### One switch: "Stay awake while AI works"

Turn it on and Wakey takes care of the rest. It looks at your lid, external monitor, and power, then picks the right protection:

| Your Mac right now | Wakey turns on |
|---|---|
| Lid open, plugged in | Sleep block (stage 4) |
| Lid open, on battery | Sleep block, only if **Keep on battery** is on. Lets go at your battery floor (20% by default) |
| Clamshell (lid closed, external monitor, plugged in) | Sleep block + Lid mode, so turning off the monitor won't sleep the Mac |
| Lid closed, no monitor | Lid mode, only if you turned on **Keep going with the lid closed and no display** |

The screen still turns off and locks as usual. Only the Mac itself stays awake.

### Other options

- **Stay awake between tasks**: keeps the Mac reachable for remote access, such as controlling Claude from your phone, even while the AI is idle.
- **Timer**: 30 min, 1 hr, 2 hr, or until you turn it off.
- **Turn off screen and step away**: turns the screen off right away while your AI keeps working. In clamshell mode, use this instead of the monitor's power button.
- **Advanced**: manual switches for *Prevent sleep*, *Keep screen on*, and *Stay awake with lid closed*. They stay on no matter what auto mode decides.

---

## Supported AI apps

| App | How Wakey knows it's working |
|---|---|
| Claude Code (Claude app and terminal) | Exact: start and finish signals |
| ChatGPT (Codex) | The app's own signal |
| Antigravity | Estimated from activity |
| Terminal agents (`claude`, `codex`) | Process activity |
| Cloud tasks (Claude chat, ChatGPT chat and Deep Research, Codex cloud, Claude Code on the web) | Not needed. They run on servers, not on your Mac |

You can choose which apps to watch in **Settings › Detection**.

---

## Common setups

**"I leave AI running with the lid open."**
Turn on *Stay awake while AI works*. That's it.

**"I use clamshell mode and control my AI remotely."**
Turn on *Stay awake while AI works* and *Stay awake between tasks*. The screen still turns off after a minute, but the Mac stays reachable. Lid mode turns on by itself, so a sleeping monitor won't put your Mac to sleep.

**"I want to close the lid and carry my MacBook."**
Turn on *Keep going with the lid closed and no display*. Wakey puts the Mac to sleep as soon as the work ends. Keep it out of tight bags: MacBook Air has no fan and can get warm.

---

## Settings

| Setting | Options |
|---|---|
| Language | English (default), 한국어, 日本語 |
| Appearance | System, Light, Dark |
| Launch at login | On / Off |
| Stay awake between tasks | On / Off |
| Release after AI finishes | 1, 5, or 10 minutes |
| Stop on battery below | 10%, 20%, or 30% |
| Lid mode helper | Install once with your admin password |
| Turn on lid mode in clamshell | On / Off |
| Turn off when the Mac gets hot | On / Off |
| Detection | Choose which AI apps to watch |

---

## Safety and privacy

- **Lid mode needs your admin password once.** It changes a system power setting, so Wakey installs a small helper.
- **Lid mode always turns itself off** when Wakey quits or crashes, when the Mac gets hot, or when the battery reaches your floor.
- **Low-battery sleep can't be blocked.** Nothing can stop it, so Wakey lets go early and tells you.
- **Wakey only checks app status.** It never reads your prompts, code, or files.

---

## Requirements

- macOS 13 Ventura or later
- Apple silicon or Intel Mac

## Install

1. Download **Wakey.dmg** from the [latest release](https://github.com/tail-s/wakey/releases/latest).
2. Open it and drag **Wakey** into the **Applications** folder.
3. Open Wakey. Its icon appears in the menu bar.

Releases are signed with Developer ID and notarized by Apple.

### Build from source

You need Xcode 16 or later.

```sh
scripts/build-app.sh
open build/Wakey.app
```

The Wakey icon appears in the menu bar. To use **Lid mode**:

1. Move `Wakey.app` to the Applications folder and open it from there.
2. Open **Settings › General › Lid mode** and click **Install…**.
3. Allow Wakey in **System Settings › General › Login Items & Extensions**.

The build script signs the app with your first "Developer ID Application" certificate. Without one the app is signed ad hoc, and everything works except Lid mode.

Other useful commands:

| Command | What it does |
|---|---|
| `swift test` | Runs the unit tests |
| `build/Wakey.app/Contents/MacOS/Wakey --status` | Prints what Wakey detects and decides, without changing anything |
| `build/Wakey.app/Contents/MacOS/Wakey --snapshot <folder>` | Saves screenshots of the menu and Settings in every language |
| `swift scripts/make-icon.swift assets/icon.png assets` | Rebuilds the app icons from `assets/icon.png` |
| `scripts/make-dmg.sh 0.1.0` | Packages `build/Wakey.app` into `build/Wakey-0.1.0.dmg` |

### Releasing

Pushing a tag like `v0.1.0` runs [GitHub Actions](.github/workflows/build.yml). It tests, builds a universal app, signs it with Developer ID, notarizes it, and publishes `Wakey-0.1.0.dmg` on GitHub Releases. The release notes are that version's section of [CHANGELOG.md](CHANGELOG.md).

1. In CHANGELOG.md, rename `[Unreleased]` to the version, for example `## [0.1.0] - 2026-11-05`.
2. Commit, then run `git tag v0.1.0 && git push origin main v0.1.0`.

Signing and notarizing need these repository secrets. Without them the DMG is signed ad hoc and not notarized.

| Secret | Value |
|---|---|
| `MACOS_CERT_P12` | Developer ID Application certificate (.p12), base64 |
| `MACOS_CERT_PASSWORD` | Password of that .p12 |
| `NOTARY_KEY_P8` | App Store Connect API key (.p8), base64 |
| `NOTARY_KEY_ID` | Key ID of that API key |
| `NOTARY_ISSUER_ID` | Issuer ID from App Store Connect |

---

## FAQ

**Will my screen stay on?**
No. By default only the Mac stays awake, and the screen turns off and locks as usual. To keep the screen on, turn on *Advanced › Keep screen on*.

**Can I just use `caffeinate`?**
For stage 4, yes: `caffeinate -i` works while the lid is open. Stage 5 needs `sudo pmset -a disablesleep 1`, and you must remember to undo it. Wakey does both for you and undoes them automatically.

**Why does turning off my monitor sleep my Mac in clamshell mode?**
With the lid closed, macOS treats "no monitor" the same as closing the lid. Use *Turn off screen and step away* instead, or let Wakey's Lid mode handle it.

---

## What's new

See [CHANGELOG.md](CHANGELOG.md) for changes in each version.

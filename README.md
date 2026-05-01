# McAudio

A minimal macOS menu bar utility for switching audio output devices with one click.

The icon in your menu bar reflects your currently active output. Click it to see your configured outputs and switch instantly. A settings window lets you rename devices, assign custom icons, hide unused ones, configure a quick-switch pair, and toggle launch at login.

> **Disclosure:** This application was designed and built entirely through prompting [Claude](https://claude.ai) (Anthropic). No code was written by hand. Unit tests and a protocol-based mock layer serve as the primary guardrail to verify that the audio-switching logic, configuration persistence, and icon-mapping behaviour are correct. See [Testing](#testing) for details.

> **Trust & safety:** McAudio makes no network requests and touches nothing outside CoreAudio and its own preferences. Read [Safety & trust](docs/security.md) for a full breakdown of what the app does on your system, what Apple's Gatekeeper warning actually means, and how to run entirely from source if you prefer.

---

## Requirements

- macOS 13 (Ventura) or later  
- Apple Silicon (arm64)

---

## Features

- **One-click switching** — click the menu bar icon, click a device. Done.
- **Adaptive icon** — the menu bar icon changes to reflect the active output's assigned symbol
- **Per-device volume memory** — McAudio silently saves each device's volume level when you leave it and restores it when you return. No configuration needed; it happens automatically on every switch.
- **Quick-switch pair** — designate any two devices as a pair in Settings. Press **⌥⇧P** to toggle between them instantly from anywhere, regardless of what is currently playing.
- **Keyboard shortcuts** — press **⌥⇧M** to open the output menu from anywhere without touching the mouse. While the menu is open, press **1–9** to switch directly to that device.
- **Settings** — per-device toggle (show/hide in menu), custom short name, icon picker from SF Symbols
- **Live updates** — the menu and icon refresh automatically when audio devices are connected or disconnected, and immediately when settings change
- **Launch at login** — toggle in Settings, backed by `SMAppService` (macOS 13+)
- **No Dock icon** — pure menu bar utility, stays out of your way

### Keyboard shortcuts

| Shortcut | Action |
|---|---|
| **⌥⇧M** | Open the output menu |
| **1–9** | Switch to that device (while menu is open) |
| **⌥⇧P** | Toggle between the two paired devices |

### Setting up the quick-switch pair

1. Open McAudio → **Settings…**
2. In the **Outputs** list, tick the **Pair** checkbox for exactly two devices — the checkboxes for all other devices grey out automatically once two are selected.
3. Press **⌥⇧P** from anywhere to jump between them. If you are already on one of the pair devices it switches to the other; if you are on neither it switches to the first one.

### How volume memory works

When you switch away from a device McAudio reads its current system volume and saves it alongside that device's other settings. When you switch back, the saved level is restored automatically. Nothing is shown in the UI — it simply works. If a device does not support software volume control (some HDMI outputs, for example) it is silently skipped.

---

## Download & install

1. Go to [Releases](https://github.com/niels-emmer/McAudio/releases/latest) and download `McAudio-<version>.dmg`
2. Open the DMG — a Finder window opens with the app and an Applications shortcut
3. Drag **McAudio** onto **Applications**
4. Eject the DMG
5. Remove the macOS quarantine flag (required for apps not distributed via the App Store):
   ```bash
   xattr -dr com.apple.quarantine /Applications/McAudio.app
   ```
6. Open McAudio from Launchpad or Spotlight — the speaker icon appears in your menu bar

> **Why step 5?** macOS quarantines apps downloaded from the internet that lack an Apple Developer certificate. The `xattr` command removes that flag. Alternatively, after the first blocked attempt, go to System Settings → Privacy & Security → **Open Anyway**. See [Safety & trust](docs/security.md) for a full explanation of what the warning means, what McAudio does on your system, and how to run from source instead.

To launch automatically at login: open McAudio → click the menu bar icon → **Settings…** → enable **Launch at login**.

---

## Upgrade

1. Download the new DMG from [Releases](https://github.com/niels-emmer/McAudio/releases)
2. Quit the running instance (menu bar icon → **Quit McAudio**)
3. Open the new DMG and drag McAudio to Applications, replacing the existing copy
4. Launch McAudio

Your settings (device names, icons, enabled state, pair selection, saved volumes) are preserved in UserDefaults across upgrades.

---

## Uninstall

```bash
# Quit and remove the app
pkill McAudio
rm -rf /Applications/McAudio.app

# Remove saved preferences (optional)
defaults delete com.nielsemmer.mcaudio
```

---

## Testing

The core audio logic lives in a separate `AudioCore` library target backed by a `MockAudioProvider`. This allows the business logic to be unit-tested without real hardware:

```
Tests/AudioCoreTests/
  ConfigStoreTests.swift      — UserDefaults round-trip, defaults for unknown devices
  CustomNameTests.swift       — custom name and icon symbol overrides
  DeviceFilteringTests.swift  — provider enumeration and error propagation
  IconMappingTests.swift      — every TransportType maps to the expected SF Symbol
  PairAndVolumeTests.swift    — pair device UIDs, backward-compat decoding, mock volume
```

Run the suite:

```bash
swift test
```

Expected output: **30 tests, 0 failures**.

Because this project is AI-generated, the tests act as the primary safety net. Any change to audio device handling, configuration persistence, or icon mapping must keep the tests green. The protocol-based design (`AudioDeviceProviding`) ensures the real CoreAudio implementation can always be swapped with a mock, making regressions detectable without hardware.

---

## Developing

### Prerequisites

- Xcode Command Line Tools (`xcode-select --install`)
- No other dependencies

### Run locally

```bash
git clone https://github.com/niels-emmer/McAudio.git
cd McAudio
swift run McAudio
```

The menu bar icon appears immediately. No bundle required for development.

### Project structure

```
Sources/
  AudioCore/          — testable library: CoreAudio wrapper, models, config store
  McAudioApp/         — executable: AppKit menu bar + SwiftUI settings window
Tests/
  AudioCoreTests/     — XCTest unit tests for AudioCore
scripts/
  bundle.sh           — assembles dist/McAudio.app and dist/McAudio-<version>.dmg
  release.sh          — bumps version, commits, tags, and pushes a release
Info.plist            — bundle metadata (LSUIElement=YES, version string)
```

### Build a release bundle

```bash
./scripts/bundle.sh
# Produces:
#   dist/McAudio.app
#   dist/McAudio-<version>.dmg   ← drag-to-Applications installer
```

---

## Troubleshooting

**The app doesn't appear in the menu bar**  
Check Activity Monitor — if `McAudio` is running but invisible, the menu bar may be full. Try hiding some other menu bar items.

**Switching audio doesn't work**  
McAudio uses the CoreAudio HAL to set the default output device, the same mechanism macOS itself uses. If switching fails, check System Settings → Sound to confirm the device is available.

**⌥⇧P does nothing**  
The pair shortcut requires exactly two devices to have their **Pair** checkbox ticked in Settings. The Shortcuts section in Settings shows a note when the pair is not yet configured.

**Launch at login shows "Approval required"**  
Click **Open** next to the notice to jump to System Settings → General → Login Items, then enable McAudio there.

**Settings changes don't stick**  
Settings save to UserDefaults on every interaction. If changes don't persist across restarts, verify with:

```bash
defaults read com.nielsemmer.mcaudio
```

**"Apple could not verify McAudio is free of malware"**  
Expected for apps without an Apple Developer certificate — it is an identity warning, not a finding. See [Safety & trust](docs/security.md) for a full explanation. Quick fix:
```bash
xattr -dr com.apple.quarantine /Applications/McAudio.app
```
Or: System Settings → Privacy & Security → **Open Anyway**. Prefer to skip the binary entirely? [Run from source](docs/security.md#run-from-source-no-binary-trust-required) in three commands.

---

## Attribution

Designed and built by **[Niels Emmer](https://github.com/niels-emmer)** with **[Claude](https://claude.ai)** (Anthropic claude-sonnet-4-6).

All source code, architecture decisions, and documentation were produced through iterative prompting. The human role was requirements, direction, and testing. Claude wrote the code.

---

## License

MIT — see [LICENSE](LICENSE) if present, or treat as freely usable.

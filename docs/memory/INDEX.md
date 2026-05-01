# McAudio — agent memory

> Always read this file at the start of a McAudio session.

## What it is

macOS menu bar utility (NSStatusItem) for one-click audio output switching. No Dock icon, no Xcode project, ~290 KB binary, zero dependencies.

## Stack

- Swift 6.3.1 / swift-tools-version 5.9 (Swift 5 language mode — not Swift 6 strict concurrency)
- AppKit: NSStatusItem + NSMenu for menu bar
- SwiftUI: preferences window only (NSHostingView inside NSWindowController)
- CoreAudio C API: device enumeration, default-output switching, per-device volume get/set
- Carbon HIToolbox: global hotkey registration (RegisterEventHotKey)
- ServiceManagement: `SMAppService.mainApp` for launch-at-login
- UserDefaults: config persistence key `com.mcaudio.deviceConfigurations`
- No third-party dependencies

## Targets

| Target | Type | Purpose |
|---|---|---|
| `AudioCore` | Library | CoreAudio wrapper, models, config store — fully testable with mock |
| `McAudioApp` | Executable | AppKit entry point, menu bar, preferences window, hotkeys |
| `AudioCoreTests` | Test | 30 XCTest unit tests |

## Key files

| File | Purpose |
|---|---|
| `Sources/AudioCore/AudioDevice.swift` | Model + TransportType → SF Symbol mapping |
| `Sources/AudioCore/CoreAudioProvider.swift` | Real HAL impl + ChangeToken HAL listener + volume get/set |
| `Sources/AudioCore/MockAudioProvider.swift` | Injectable mock for unit tests (includes volumeStore) |
| `Sources/AudioCore/ConfigurationStore.swift` | UserDefaults encode/decode; posts `configurationsDidChange` on write; `pairDeviceUIDs` computed property |
| `Sources/McAudioApp/StatusBarController.swift` | NSMenuDelegate + NotificationCenter observer; rebuilds on open and config change; `switchToDevice` saves/restores volume; `togglePair` |
| `Sources/McAudioApp/HotkeyManager.swift` | Carbon RegisterEventHotKey for ⌥⇧M (open menu) and ⌥⇧P (toggle pair) |
| `Sources/McAudioApp/PreferencesWindowController.swift` | Settings window: device list with Show/Pair columns, launch-at-login toggle, shortcuts section, version badge |
| `Sources/McAudioApp/LoginItemManager.swift` | `SMAppService.mainApp` wrapper for launch-at-login |
| `scripts/bundle.sh` | Builds `dist/McAudio.app` + `dist/McAudio-{VERSION}.dmg` (drag-to-Applications layout) |
| `scripts/release.sh` | Bumps version in Info.plist, commits, creates annotated tag, pushes |
| `.claude/hooks/session-complete.sh` | UserPromptSubmit hook: injects git context when "session complete" is prompted |
| `.github/workflows/release.yml` | GitHub Actions: builds DMG on tag push, creates GitHub release with DMG artifact |
| `Info.plist` | Source of truth for version (`CFBundleShortVersionString`); updated by release.sh |

## DeviceConfiguration model

```swift
struct DeviceConfiguration: Codable {
    var customName: String      // empty = use device name
    var sfSymbol: String        // empty = use transport-type default
    var isEnabled: Bool         // show in menu
    var isInPair: Bool          // part of quick-switch pair (max 2)
    var savedVolume: Float?     // scalar 0.0–1.0; nil = not yet captured or unsupported
}
```

Custom `init(from:)` decoder provides backward compat: `isInPair` defaults to `false` if absent in stored JSON.

## Per-device volume memory

On every `switchToDevice(_:)` call:
1. Read current device's scalar volume via `kAudioDevicePropertyVolumeScalar` (output scope, main element)
2. Write it to `DeviceConfiguration.savedVolume` using `store.save(all)` (silent — no notification posted)
3. After setting the new default device, call `provider.setVolume(saved, for: device.id)` if `savedVolume != nil`

Devices that don't support software volume (`AudioObjectHasProperty` returns false, or property not settable) are silently skipped.

## Quick-switch pair

- `ConfigurationStore.pairDeviceUIDs` returns UIDs of all configs where `isInPair == true`
- `StatusBarController.togglePair()`: reads pair UIDs, finds the one that isn't currently active, calls `switchToDevice`
- If neither pair device is currently active, switches to the first pair device
- Hotkey: ⌥⇧P (does nothing if fewer than 2 pair devices are configured)

## Keyboard shortcuts (HotkeyManager)

- ⌥⇧M → `statusItem.button?.performClick(nil)` → opens the menu
- ⌥⇧P → `togglePair()`
- While menu is open: keys 1–9 activate the corresponding device items (`keyEquivalentModifierMask = []`)
- Carbon `RegisterEventHotKey` with `optionKey | shiftKey` modifier mask; no Accessibility permission required
- The top-level `hotkeyEventCallback` C function bridges Carbon events to `HotkeyManager` via `userData` pointer

## Live-update wiring

Settings changes propagate via two paths:
1. `ConfigurationStore.upsert` → posts `ConfigurationStore.didChange` → `StatusBarController` observes → `refresh()`
2. `NSMenuDelegate.menuWillOpen` → always rebuilds from fresh store data on menu open

## Release workflow ("session complete")

When the user prompts "session complete", the `.claude/hooks/session-complete.sh` hook fires and outputs git context (current version, last tag, commits since last tag). Claude then:

1. Reviews the commits to decide **minor** (new feature/behaviour) or **patch** (bugfix/refactor/docs)
2. Writes a one-sentence description
3. Runs: `./scripts/release.sh <minor|patch> "<description>"`
4. The script: bumps `Info.plist` version → `git add -A` → commits → annotated tag → pushes branch + tag
5. GitHub Actions (`release.yml`) picks up the tag push → builds DMG → creates GitHub release with DMG attached

Use **major** only for breaking changes (e.g. dropped macOS version support, incompatible config format).

## Commands

```bash
swift test                              # 30 unit tests
swift run McAudio                      # dev run (no bundle)
./scripts/bundle.sh                     # release .app + .dmg → dist/
./scripts/release.sh minor "desc"       # bump minor, commit, tag, push
./scripts/release.sh patch "desc"       # bump patch, commit, tag, push
pkill McAudio                          # stop running instance
defaults delete com.nielsemmer.mcaudio # wipe saved prefs
```

## GitHub

- Repo: https://github.com/niels-emmer/McAudio
- Releases: https://github.com/niels-emmer/McAudio/releases

## Status

- v1.2.0 — working, 30/30 tests green
- Per-device volume memory: transparent, no UI, silently skips unsupported devices
- Quick-switch pair: 2-device pair selectable in Settings, toggled via ⌥⇧P
- Keyboard shortcuts: ⌥⇧M opens menu; 1–9 switch while menu open; ⌥⇧P toggles pair
- Settings: Show/Pair column headers, greyed pair checkboxes once 2 selected, Shortcuts section
- DMG: drag-to-Applications layout, ~88 KB compressed
- Release automation: hooks + GitHub Actions in place

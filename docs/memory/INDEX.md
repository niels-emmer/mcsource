# mcsource — agent memory

> Always read this file at the start of a mcsource session.

## What it is

macOS menu bar utility (NSStatusItem) for one-click audio output switching. No Dock icon, no Xcode project, ~290 KB binary, zero dependencies.

## Stack

- Swift 6.3.1 / swift-tools-version 5.9 (Swift 5 language mode — not Swift 6 strict concurrency)
- AppKit: NSStatusItem + NSMenu for menu bar
- SwiftUI: preferences window only (NSHostingView inside NSWindowController)
- CoreAudio C API: device enumeration and default-output switching
- ServiceManagement: `SMAppService.mainApp` for launch-at-login
- UserDefaults: config persistence key `com.mcsource.deviceConfigurations`
- No third-party dependencies

## Targets

| Target | Type | Purpose |
|---|---|---|
| `AudioCore` | Library | CoreAudio wrapper, models, config store — fully testable with mock |
| `McSourceApp` | Executable | AppKit entry point, menu bar, preferences window |
| `AudioCoreTests` | Test | 25 XCTest unit tests |

## Key files

| File | Purpose |
|---|---|
| `Sources/AudioCore/AudioDevice.swift` | Model + TransportType → SF Symbol mapping |
| `Sources/AudioCore/CoreAudioProvider.swift` | Real HAL impl + ChangeToken HAL listener |
| `Sources/AudioCore/MockAudioProvider.swift` | Injectable mock for unit tests |
| `Sources/AudioCore/ConfigurationStore.swift` | UserDefaults encode/decode; posts `configurationsDidChange` on write |
| `Sources/McSourceApp/StatusBarController.swift` | NSMenuDelegate + NotificationCenter observer; rebuilds on open and config change |
| `Sources/McSourceApp/PreferencesWindowController.swift` | Settings window: device list, launch-at-login toggle, version badge with GitHub link |
| `Sources/McSourceApp/LoginItemManager.swift` | `SMAppService.mainApp` wrapper for launch-at-login |
| `scripts/bundle.sh` | Builds `dist/McSource.app` + `dist/McSource-{VERSION}.dmg` (drag-to-Applications layout) |
| `scripts/release.sh` | Bumps version in Info.plist, commits, creates annotated tag, pushes |
| `.claude/hooks/session-complete.sh` | UserPromptSubmit hook: injects git context when "session complete" is prompted |
| `.github/workflows/release.yml` | GitHub Actions: builds DMG on tag push, creates GitHub release with DMG artifact |
| `Info.plist` | Source of truth for version (`CFBundleShortVersionString`); updated by release.sh |

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
swift test                              # 25 unit tests
swift run McSource                      # dev run (no bundle)
./scripts/bundle.sh                     # release .app + .dmg → dist/
./scripts/release.sh minor "desc"       # bump minor, commit, tag, push
./scripts/release.sh patch "desc"       # bump patch, commit, tag, push
pkill McSource                          # stop running instance
defaults delete com.nielsemmer.mcsource # wipe saved prefs
```

## GitHub

- Repo: https://github.com/niels-emmer/mcsource
- Releases: https://github.com/niels-emmer/mcsource/releases

## Status

- v1.0.0 — working, 25/25 tests green
- Settings: auto-save, Done button, launch-at-login toggle, version badge linked to GitHub release
- DMG: drag-to-Applications layout, ~88 KB compressed
- Release automation: hooks + GitHub Actions in place

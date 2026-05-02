# Safety & trust

McAudio is a small open-source utility. This page explains the macOS security warning you may see, what Apple's code-signing process actually guarantees, what McAudio does and does not do on your system, and how to run it directly from source if you prefer not to trust a pre-built binary.

---

## The Gatekeeper warning

When you download McAudio from GitHub and try to open it, macOS may show:

> *"Apple could not verify 'McAudio' is free of malware that may harm your Mac or compromise your privacy."*

This warning appears because McAudio is not signed with a paid Apple Developer certificate. It does **not** mean the app was found to contain malware — it means macOS cannot verify the identity of who built it through Apple's paid programme.

To dismiss it, run this once after dragging the app to Applications:

```bash
xattr -dr com.apple.quarantine /Applications/McAudio.app
```

Or: System Settings → Privacy & Security → scroll down → **Open Anyway**.

---

## What Apple's $99/year Developer Programme actually provides

Paying Apple gives a developer two things:

1. **A Developer ID certificate** — Apple countersigns the developer's key, linking the binary to a registered legal identity. If malware is distributed under that certificate, Apple can revoke it remotely.

2. **Notarization** — the developer uploads the binary to Apple's servers. Automated scanners check it against known malware signatures and policy rules. If it passes, Apple staples a ticket to the app and Gatekeeper shows no warning on first launch.

### What it does *not* guarantee

- Apple does **not read or audit the source code**
- There is **no human review** of what the application actually does
- A notarized app can still be harmful — it just passed automated scans and came from an identified account
- The certificate is an **accountability mechanism**, not a safety endorsement

The warning you see with McAudio is entirely about *identity* (unknown developer) — not about the code itself having been found dangerous.

---

## What McAudio actually does on your system

McAudio is as minimal as a macOS app can be. Here is the complete list of things it does:

| Action | API used | Purpose |
|---|---|---|
| List audio output devices | CoreAudio `kAudioHardwarePropertyDevices` | Populate the menu |
| Read the active output | CoreAudio `kAudioHardwarePropertyDefaultOutputDevice` | Show the current device |
| Switch the active output | CoreAudio `AudioObjectSetPropertyData` | One-click switching |
| Watch for device changes | CoreAudio `AudioObjectAddPropertyListener` | Live menu updates |
| Save your settings | `UserDefaults` (`com.nielsemmer.mcaudio`) | Remember names, icons, toggle states |
| Register as a login item | `SMAppService.mainApp.register()` | Launch at login (only if you enable it) |

That is the entire surface area. McAudio:

- Makes **no network requests**
- Reads **no files** outside its own preferences
- Has **no access** to microphone, camera, contacts, location, or any other sensitive resource
- Cannot **elevate privileges** — it runs as your normal user account
- Does **not** collect or transmit any data

You can verify this independently: the full source is on GitHub and the binary has no network entitlements.

---

## The source is the guarantee

Because this project is AI-generated, the source code on GitHub *is* the safety argument — not a certificate. Every meaningful behaviour is covered by unit tests:

```
Tests/AudioCoreTests/
  ConfigStoreTests.swift      — settings saved and loaded correctly
  CustomNameTests.swift       — name and icon overrides work as expected
  DeviceFilteringTests.swift  — only output devices are shown; errors propagate correctly
  IconMappingTests.swift      — every device type maps to the right symbol
```

Run them yourself:

```bash
git clone https://github.com/niels-emmer/McAudio.git
cd McAudio
swift test
```

Expected: **34 tests, 0 failures**.

---

## Run from source (no binary trust required)

If you prefer not to run a pre-built binary at all, you can build and run McAudio entirely from source in a few commands. You need Xcode Command Line Tools (`xcode-select --install`) and nothing else.

```bash
# Clone
git clone https://github.com/niels-emmer/McAudio.git
cd McAudio

# Inspect the code (optional but encouraged)
open .

# Run tests
swift test

# Run the app
swift run McAudio
```

`swift run` compiles and launches the app directly. The menu bar icon appears immediately. No installer, no binary, no Gatekeeper warning — macOS trusts code you compile yourself.

To stop it:

```bash
pkill McAudio
```

### Build your own .app bundle

If you want a persistent installation that you built yourself:

```bash
./scripts/bundle.sh
# Produces dist/McAudio.app — drag to /Applications
open dist/McAudio.app
```

Because you built it on your machine, macOS does not quarantine it.

---

## Reporting concerns

If you believe you have found a security issue or unexpected behaviour, please [open an issue](https://github.com/niels-emmer/McAudio/issues) on GitHub with as much detail as possible.

import AppKit
import AudioCore

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let provider: any AudioDeviceProviding
    private let store: ConfigurationStore
    private var changeToken: AnyObject?
    private let hotkeyManager = HotkeyManager()
    private lazy var preferencesController = PreferencesWindowController(
        provider: provider, store: store
    )

    init(provider: any AudioDeviceProviding, store: ConfigurationStore) {
        self.provider = provider
        self.store    = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        changeToken = provider.observeChanges { [weak self] in self?.refresh() }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: ConfigurationStore.didChange,
            object: nil
        )

        hotkeyManager.onOpenMenu   = { [weak self] in self?.statusItem.button?.performClick(nil) }
        hotkeyManager.onTogglePair = { [weak self] in self?.togglePair() }

        refresh()
    }

    private func refresh() {
        rebuildMenu()
        updateIcon()
    }

    // MARK: - Icon

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName: String
        if let active = try? provider.defaultOutputDevice() {
            let config = store.configuration(for: active.uid, fallbackDevice: active)
            symbolName = config.sfSymbol.isEmpty ? active.transportType.defaultSFSymbol : config.sfSymbol
        } else {
            symbolName = "speaker.slash"
        }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Audio Output")
        image?.isTemplate = true
        button.image = image
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let menu = NSMenu()
        let configs  = store.loadAll()
        let devices  = (try? provider.outputDevices()) ?? []
        let activeUID = (try? provider.defaultOutputDevice())?.uid

        var keyIndex = 1
        for device in devices {
            let config = configs[device.uid]
            guard config?.isEnabled ?? true else { continue }

            let displayName = config?.customName.isEmpty == false
                ? config!.customName
                : device.name

            let key = keyIndex <= 9 ? "\(keyIndex)" : ""
            let item = NSMenuItem(
                title: displayName,
                action: #selector(switchDevice(_:)),
                keyEquivalent: key
            )
            item.keyEquivalentModifierMask = []
            item.target = self
            item.representedObject = device
            if device.uid == activeUID { item.state = .on }

            let sym = config?.sfSymbol.isEmpty == false
                ? config!.sfSymbol
                : device.transportType.defaultSFSymbol
            if let icon = NSImage(systemSymbolName: sym, accessibilityDescription: nil) {
                item.image = icon
            }

            menu.addItem(item)
            keyIndex += 1
        }

        if devices.filter({ configs[$0.uid]?.isEnabled ?? true }).isEmpty {
            let empty = NSMenuItem(title: "No outputs configured", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit McAudio",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func switchDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        switchToDevice(device)
    }

    @objc private func configDidChange() { refresh() }

    @objc private func openSettings() {
        preferencesController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Switch with volume memory

    private func switchToDevice(_ device: AudioDevice) {
        // Persist current device's volume before leaving it
        if let current = try? provider.defaultOutputDevice() {
            if let vol = provider.getVolume(for: current.id) {
                var all = store.loadAll()
                if var cfg = all[current.uid] {
                    cfg.savedVolume = vol
                    all[current.uid] = cfg
                    store.save(all)   // silent — no config-change notification needed
                }
            }
        }

        try? provider.setDefaultOutputDevice(device)

        // Restore the saved volume for the newly active device
        let cfg = store.configuration(for: device.uid, fallbackDevice: device)
        if let saved = cfg.savedVolume {
            provider.setVolume(saved, for: device.id)
        }

        refresh()
    }

    // MARK: - Pair toggle

    private func togglePair() {
        let pairUIDs = store.pairDeviceUIDs
        guard pairUIDs.count == 2 else { return }
        let currentUID = (try? provider.defaultOutputDevice())?.uid
        let targetUID  = pairUIDs.first(where: { $0 != currentUID }) ?? pairUIDs[0]
        let devices    = (try? provider.outputDevices()) ?? []
        guard let target = devices.first(where: { $0.uid == targetUID }) else { return }
        switchToDevice(target)
    }
}

// MARK: - NSMenuDelegate

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
        updateIcon()
    }
}

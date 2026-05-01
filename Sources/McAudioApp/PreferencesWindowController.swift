import AppKit
import ServiceManagement
import SwiftUI
import AudioCore

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let provider: any AudioDeviceProviding
    private let store: ConfigurationStore

    init(provider: any AudioDeviceProviding, store: ConfigurationStore) {
        self.provider = provider
        self.store = store

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "McAudio \u{2014} Settings"
        window.center()
        super.init(window: window)
        window.delegate = self

        let view = PreferencesView(provider: provider, store: store) { [weak window] in
            window?.orderOut(nil)
        }
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

// MARK: - PreferencesView

private let availableSymbols: [String] = [
    "speaker.wave.2",
    "headphones",
    "tv",
    "airplayaudio",
    "hifispeaker",
    "bolt",
    "waveform",
    "earbuds",
    "hifispeaker.fill",
    "speaker.slash",
]

struct PreferencesView: View {
    let provider: any AudioDeviceProviding
    let store: ConfigurationStore
    var onDone: (() -> Void)?

    @State private var devices: [AudioDevice] = []
    @State private var configurations: [String: DeviceConfiguration] = [:]
    @State private var launchAtLogin: Bool = LoginItemManager.shared.isEnabled
    @State private var loginItemNeedsApproval: Bool = LoginItemManager.shared.requiresApproval

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Outputs") {
                    ForEach(devices) { device in
                        DeviceRow(
                            device: device,
                            config: configBinding(for: device)
                        )
                        .padding(.vertical, 2)
                    }
                }

                Section("General") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            LoginItemManager.shared.setEnabled(newValue)
                            launchAtLogin = LoginItemManager.shared.isEnabled
                            loginItemNeedsApproval = LoginItemManager.shared.requiresApproval
                        }

                    if loginItemNeedsApproval {
                        HStack {
                            Text("Approval required — open System Settings \u{203A} General \u{203A} Login Items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Open\u{2026}") {
                                SMAppService.openSystemSettingsLoginItems()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            HStack {
                Text("\(devices.count) output\(devices.count == 1 ? "" : "s") detected")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                versionBadge
                Spacer()
                Button("Done") { onDone?() }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear { reload() }
    }

    @ViewBuilder
    private var versionBadge: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let releaseURL = version != "dev"
            ? URL(string: "https://github.com/niels-emmer/McAudio/releases/tag/v\(version)")
            : nil
        if let url = releaseURL {
            Link("v\(version)", destination: url)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("v\(version)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func reload() {
        devices = (try? provider.outputDevices()) ?? []
        configurations = store.loadAll()
    }

    private func configBinding(for device: AudioDevice) -> Binding<DeviceConfiguration> {
        let fallback = DeviceConfiguration(
            customName: "",
            sfSymbol: device.transportType.defaultSFSymbol,
            isEnabled: true
        )
        return Binding(
            get: { self.configurations[device.uid] ?? fallback },
            set: { newValue in
                self.configurations[device.uid] = newValue
                self.store.upsert(newValue, for: device.uid)
            }
        )
    }
}

struct DeviceRow: View {
    let device: AudioDevice
    @Binding var config: DeviceConfiguration

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $config.isEnabled)
                .labelsHidden()
                .frame(width: 36)

            Image(systemName: resolvedSymbol)
                .frame(width: 22)
                .foregroundStyle(config.isEnabled ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.body)
                    .foregroundStyle(config.isEnabled ? .primary : .secondary)
                TextField("Custom name\u{2026}", text: $config.customName)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            Picker("", selection: $config.sfSymbol) {
                ForEach(availableSymbols, id: \.self) { sym in
                    Image(systemName: sym)
                        .help(sym)
                        .tag(sym)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 54)
            .labelsHidden()
        }
    }

    private var resolvedSymbol: String {
        config.sfSymbol.isEmpty ? device.transportType.defaultSFSymbol : config.sfSymbol
    }
}

import Foundation

public final class ConfigurationStore {
    public static let didChange = Notification.Name("com.mcaudio.configurationsDidChange")

    private let defaults: UserDefaults
    private let storageKey = "com.mcaudio.deviceConfigurations"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadAll() -> [String: DeviceConfiguration] {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([String: DeviceConfiguration].self, from: data)
        else { return [:] }
        return decoded
    }

    public func save(_ configurations: [String: DeviceConfiguration]) {
        guard let data = try? JSONEncoder().encode(configurations) else { return }
        defaults.set(data, forKey: storageKey)
    }

    public func configuration(for uid: String, fallbackDevice: AudioDevice? = nil) -> DeviceConfiguration {
        if let existing = loadAll()[uid] { return existing }
        let symbol = fallbackDevice?.transportType.defaultSFSymbol ?? "speaker.wave.2"
        return DeviceConfiguration(customName: "", sfSymbol: symbol, isEnabled: true)
    }

    public func upsert(_ config: DeviceConfiguration, for uid: String) {
        var all = loadAll()
        all[uid] = config
        save(all)
        NotificationCenter.default.post(name: ConfigurationStore.didChange, object: nil)
    }

    /// UIDs of the (up to 2) devices marked as quick-switch pair.
    public var pairDeviceUIDs: [String] {
        loadAll().compactMap { $0.value.isInPair ? $0.key : nil }
    }
}

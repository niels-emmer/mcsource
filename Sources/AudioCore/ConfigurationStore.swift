import Foundation

public final class ConfigurationStore {
    public static let didChange = Notification.Name("com.mcsource.configurationsDidChange")

    private let defaults: UserDefaults
    private let storageKey = "com.mcsource.deviceConfigurations"

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
}

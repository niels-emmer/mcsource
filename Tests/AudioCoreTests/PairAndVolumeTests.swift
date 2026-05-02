import XCTest
@testable import AudioCore

final class PairAndVolumeTests: XCTestCase {

    // MARK: - Pair UIDs

    func testPairDeviceUIDsReturnsTwoMarked() {
        let store = makeStore()
        store.upsert(DeviceConfiguration(isInPair: true),  for: "uid-a")
        store.upsert(DeviceConfiguration(isInPair: true),  for: "uid-b")
        store.upsert(DeviceConfiguration(isInPair: false), for: "uid-c")
        XCTAssertEqual(Set(store.pairDeviceUIDs), Set(["uid-a", "uid-b"]))
    }

    func testPairDeviceUIDsEmptyWhenNoneMarked() {
        let store = makeStore()
        store.upsert(DeviceConfiguration(isInPair: false), for: "uid-x")
        XCTAssertTrue(store.pairDeviceUIDs.isEmpty)
    }

    // MARK: - Backward-compat decoding

    func testDecodesLegacyConfigMissingNewFields() throws {
        // Simulates a config saved before isInPair, savedVolume, and lastKnownName existed
        let json = """
        {"customName":"","sfSymbol":"speaker.wave.2","isEnabled":true}
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(DeviceConfiguration.self, from: json)
        XCTAssertFalse(config.isInPair)
        XCTAssertNil(config.savedVolume)
        XCTAssertEqual(config.lastKnownName, "")
    }

    // MARK: - lastKnownName

    func testLastKnownNameRoundTrip() {
        let store = makeStore()
        var cfg = DeviceConfiguration()
        cfg.lastKnownName = "Sony WH-1000XM5"
        store.upsert(cfg, for: "uid-sony")
        let loaded = store.configuration(for: "uid-sony")
        XCTAssertEqual(loaded.lastKnownName, "Sony WH-1000XM5")
    }

    func testLastKnownNameDefaultsToEmpty() {
        let store = makeStore()
        let cfg = store.configuration(for: "never-seen-uid")
        XCTAssertEqual(cfg.lastKnownName, "")
    }

    // MARK: - Offline device filtering

    func testOfflineEnabledDevicesIdentifiable() {
        let store = makeStore()
        store.upsert(DeviceConfiguration(isEnabled: true),  for: "uid-online")
        store.upsert(DeviceConfiguration(isEnabled: true),  for: "uid-offline")
        store.upsert(DeviceConfiguration(isEnabled: false), for: "uid-hidden")

        let liveUIDs: Set<String> = ["uid-online"]
        let all = store.loadAll()
        let offline = all.filter { $0.value.isEnabled && !liveUIDs.contains($0.key) }

        XCTAssertEqual(offline.keys.first, "uid-offline")
        XCTAssertEqual(offline.count, 1)
    }

    func testOfflineDisabledDevicesNotShown() {
        let store = makeStore()
        store.upsert(DeviceConfiguration(isEnabled: false), for: "uid-disabled-offline")

        let liveUIDs: Set<String> = []
        let all = store.loadAll()
        let offline = all.filter { $0.value.isEnabled && !liveUIDs.contains($0.key) }

        XCTAssertTrue(offline.isEmpty)
    }

    // MARK: - Mock volume

    func testMockVolumeRoundTrip() {
        let mock = MockAudioProvider()
        mock.setVolume(0.75, for: 42)
        XCTAssertEqual(mock.getVolume(for: 42), 0.75)
    }

    func testMockVolumeNilForUnknownDevice() {
        let mock = MockAudioProvider()
        XCTAssertNil(mock.getVolume(for: 99))
    }

    // MARK: - Helpers

    private func makeStore() -> ConfigurationStore {
        let suiteName = "com.mcaudio.tests.pairvolume.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return ConfigurationStore(defaults: defaults)
    }
}

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

    func testDecodesLegacyConfigWithoutIsInPair() throws {
        let json = """
        {"customName":"","sfSymbol":"speaker.wave.2","isEnabled":true}
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(DeviceConfiguration.self, from: json)
        XCTAssertFalse(config.isInPair)
        XCTAssertNil(config.savedVolume)
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

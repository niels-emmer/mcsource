import XCTest
@testable import AudioCore

final class ConfigStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ConfigurationStore!
    private let suiteName = "com.mcaudio.tests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        store = ConfigurationStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testRoundTrip() {
        let config = DeviceConfiguration(customName: "My Headphones", sfSymbol: "headphones", isEnabled: true)
        store.upsert(config, for: "uid-1")
        let loaded = store.configuration(for: "uid-1")
        XCTAssertEqual(loaded.customName, "My Headphones")
        XCTAssertEqual(loaded.sfSymbol, "headphones")
        XCTAssertTrue(loaded.isEnabled)
    }

    func testDisabledRoundTrip() {
        let config = DeviceConfiguration(customName: "", sfSymbol: "tv", isEnabled: false)
        store.upsert(config, for: "uid-tv")
        XCTAssertFalse(store.configuration(for: "uid-tv").isEnabled)
    }

    func testDefaultsForUnknownUID() {
        let config = store.configuration(for: "unknown-uid")
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.customName.isEmpty)
    }

    func testFallbackDeviceSymbolUsedForNewUID() {
        let device = AudioDevice(id: 1, name: "AirPods", uid: "uid-bt", transportType: .bluetooth)
        let config = store.configuration(for: "uid-bt", fallbackDevice: device)
        XCTAssertEqual(config.sfSymbol, "headphones")
    }

    func testMultipleDevicesSavedAndLoaded() {
        store.upsert(DeviceConfiguration(customName: "A", sfSymbol: "tv", isEnabled: true), for: "uid-a")
        store.upsert(DeviceConfiguration(customName: "B", sfSymbol: "headphones", isEnabled: false), for: "uid-b")
        let all = store.loadAll()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all["uid-a"]?.customName, "A")
        XCTAssertFalse(all["uid-b"]!.isEnabled)
    }

    func testUpsertOverwritesExisting() {
        store.upsert(DeviceConfiguration(customName: "Old", sfSymbol: "speaker.wave.2", isEnabled: true), for: "uid-x")
        store.upsert(DeviceConfiguration(customName: "New", sfSymbol: "headphones", isEnabled: false), for: "uid-x")
        let config = store.configuration(for: "uid-x")
        XCTAssertEqual(config.customName, "New")
        XCTAssertFalse(config.isEnabled)
    }

    func testLoadAllReturnsEmptyWhenNothingSaved() {
        XCTAssertTrue(store.loadAll().isEmpty)
    }
}

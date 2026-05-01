import XCTest
@testable import AudioCore

final class DeviceFilteringTests: XCTestCase {
    func testOutputDevicesReturnsStubbed() throws {
        let mock = MockAudioProvider()
        mock.stubbedDevices = [
            AudioDevice(id: 1, name: "Speakers", uid: "uid-speakers", transportType: .builtIn),
            AudioDevice(id: 2, name: "Headphones", uid: "uid-bt", transportType: .bluetooth),
        ]
        let result = try mock.outputDevices()
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.uid), ["uid-speakers", "uid-bt"])
    }

    func testEmptyDeviceListReturnsEmpty() throws {
        let mock = MockAudioProvider()
        mock.stubbedDevices = []
        XCTAssertTrue(try mock.outputDevices().isEmpty)
    }

    func testThrowingProviderPropagatesError() {
        let mock = MockAudioProvider()
        mock.shouldThrow = true
        XCTAssertThrowsError(try mock.outputDevices())
    }

    func testSetDefaultUpdatesStubbed() throws {
        let mock = MockAudioProvider()
        let device = AudioDevice(id: 1, name: "TV", uid: "uid-tv", transportType: .hdmi)
        mock.stubbedDevices = [device]
        try mock.setDefaultOutputDevice(device)
        XCTAssertEqual(mock.setDefaultCalled?.uid, "uid-tv")
        let def = try mock.defaultOutputDevice()
        XCTAssertEqual(def?.uid, "uid-tv")
    }
}

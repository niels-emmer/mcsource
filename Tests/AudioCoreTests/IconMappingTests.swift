import XCTest
@testable import AudioCore

final class IconMappingTests: XCTestCase {
    func testBuiltIn() {
        XCTAssertEqual(AudioDevice.TransportType.builtIn.defaultSFSymbol, "speaker.wave.2")
    }

    func testBluetooth() {
        XCTAssertEqual(AudioDevice.TransportType.bluetooth.defaultSFSymbol, "headphones")
        XCTAssertEqual(AudioDevice.TransportType.bluetoothLE.defaultSFSymbol, "headphones")
    }

    func testHDMIAndDisplayPort() {
        XCTAssertEqual(AudioDevice.TransportType.hdmi.defaultSFSymbol, "tv")
        XCTAssertEqual(AudioDevice.TransportType.displayPort.defaultSFSymbol, "tv")
    }

    func testAirPlay() {
        XCTAssertEqual(AudioDevice.TransportType.airPlay.defaultSFSymbol, "airplayaudio")
    }

    func testUSB() {
        XCTAssertEqual(AudioDevice.TransportType.usb.defaultSFSymbol, "hifispeaker")
    }

    func testThunderbolt() {
        XCTAssertEqual(AudioDevice.TransportType.thunderbolt.defaultSFSymbol, "bolt")
    }

    func testVirtualAndAggregate() {
        XCTAssertEqual(AudioDevice.TransportType.virtual.defaultSFSymbol, "waveform")
        XCTAssertEqual(AudioDevice.TransportType.aggregate.defaultSFSymbol, "waveform")
    }

    func testUnknown() {
        XCTAssertEqual(AudioDevice.TransportType.unknown.defaultSFSymbol, "speaker.slash")
    }

    func testAllCasesHaveNonEmptySymbol() {
        let cases: [AudioDevice.TransportType] = [
            .builtIn, .bluetooth, .bluetoothLE, .usb, .hdmi,
            .displayPort, .airPlay, .thunderbolt, .virtual, .aggregate, .unknown
        ]
        for type in cases {
            XCTAssertFalse(type.defaultSFSymbol.isEmpty, "\(type) has empty symbol")
        }
    }
}

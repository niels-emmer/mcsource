import XCTest
@testable import AudioCore

final class CustomNameTests: XCTestCase {
    private func displayName(device: AudioDevice, config: DeviceConfiguration) -> String {
        config.customName.isEmpty ? device.name : config.customName
    }

    private func resolvedSymbol(device: AudioDevice, config: DeviceConfiguration) -> String {
        config.sfSymbol.isEmpty ? device.transportType.defaultSFSymbol : config.sfSymbol
    }

    func testCustomNameOverridesDeviceName() {
        let device = AudioDevice(id: 1, name: "MacBook Pro Speakers", uid: "uid-1", transportType: .builtIn)
        let config = DeviceConfiguration(customName: "Built-in", sfSymbol: "", isEnabled: true)
        XCTAssertEqual(displayName(device: device, config: config), "Built-in")
    }

    func testEmptyCustomNameFallsBackToDeviceName() {
        let device = AudioDevice(id: 1, name: "MacBook Pro Speakers", uid: "uid-1", transportType: .builtIn)
        let config = DeviceConfiguration(customName: "", sfSymbol: "", isEnabled: true)
        XCTAssertEqual(displayName(device: device, config: config), "MacBook Pro Speakers")
    }

    func testCustomSymbolOverridesDefault() {
        let device = AudioDevice(id: 2, name: "AirPods", uid: "uid-2", transportType: .bluetooth)
        let config = DeviceConfiguration(customName: "", sfSymbol: "earbuds", isEnabled: true)
        XCTAssertEqual(resolvedSymbol(device: device, config: config), "earbuds")
    }

    func testEmptySymbolFallsBackToTransportDefault() {
        let device = AudioDevice(id: 2, name: "AirPods", uid: "uid-2", transportType: .bluetooth)
        let config = DeviceConfiguration(customName: "", sfSymbol: "", isEnabled: true)
        XCTAssertEqual(resolvedSymbol(device: device, config: config), "headphones")
    }

    func testWhitespaceOnlyCustomNameIsNotEmpty() {
        let device = AudioDevice(id: 1, name: "Speakers", uid: "uid-1", transportType: .builtIn)
        let config = DeviceConfiguration(customName: "   ", sfSymbol: "", isEnabled: true)
        XCTAssertEqual(displayName(device: device, config: config), "   ")
    }
}

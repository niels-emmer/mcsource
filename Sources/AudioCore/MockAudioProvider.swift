import CoreAudio
import Foundation

public final class MockAudioProvider: AudioDeviceProviding {
    public var stubbedDevices: [AudioDevice] = []
    public var stubbedDefault: AudioDevice?
    public var setDefaultCalled: AudioDevice?
    public var shouldThrow = false

    public init() {}

    public func outputDevices() throws -> [AudioDevice] {
        if shouldThrow { throw CoreAudioError(kAudioHardwareUnspecifiedError) }
        return stubbedDevices
    }

    public func defaultOutputDevice() throws -> AudioDevice? {
        if shouldThrow { throw CoreAudioError(kAudioHardwareUnspecifiedError) }
        return stubbedDefault ?? stubbedDevices.first
    }

    public func setDefaultOutputDevice(_ device: AudioDevice) throws {
        if shouldThrow { throw CoreAudioError(kAudioHardwareUnspecifiedError) }
        setDefaultCalled = device
        stubbedDefault = device
    }

    public func observeChanges(handler: @escaping () -> Void) -> AnyObject {
        return NSObject()
    }

    // MARK: - Volume

    public var volumeStore: [AudioObjectID: Float] = [:]

    public func getVolume(for deviceID: AudioObjectID) -> Float? {
        return volumeStore[deviceID]
    }

    public func setVolume(_ volume: Float, for deviceID: AudioObjectID) {
        volumeStore[deviceID] = volume
    }
}

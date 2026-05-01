import CoreAudio
import Foundation

public protocol AudioDeviceProviding: AnyObject {
    func outputDevices() throws -> [AudioDevice]
    func defaultOutputDevice() throws -> AudioDevice?
    func setDefaultOutputDevice(_ device: AudioDevice) throws
    /// Returns an opaque token; releasing it deregisters the listener.
    func observeChanges(handler: @escaping () -> Void) -> AnyObject
    /// Returns the current scalar volume (0.0–1.0) for a device, or nil if unsupported.
    func getVolume(for deviceID: AudioObjectID) -> Float?
    /// Sets the scalar volume (0.0–1.0) for a device; silently ignored if unsupported.
    func setVolume(_ volume: Float, for deviceID: AudioObjectID)
}

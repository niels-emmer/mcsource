import Foundation

public protocol AudioDeviceProviding: AnyObject {
    func outputDevices() throws -> [AudioDevice]
    func defaultOutputDevice() throws -> AudioDevice?
    func setDefaultOutputDevice(_ device: AudioDevice) throws
    /// Returns an opaque token; releasing it deregisters the listener.
    func observeChanges(handler: @escaping () -> Void) -> AnyObject
}

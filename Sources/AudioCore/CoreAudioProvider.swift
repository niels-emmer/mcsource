import CoreAudio
import Foundation

public final class CoreAudioProvider: AudioDeviceProviding {

    public init() {}

    // MARK: - Enumerate

    public func outputDevices() throws -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        )
        guard status == kAudioHardwareNoError else { throw CoreAudioError(status) }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &dataSize, &deviceIDs
        )
        guard status == kAudioHardwareNoError else { throw CoreAudioError(status) }

        return deviceIDs.compactMap { id in
            guard hasOutputStream(deviceID: id) else { return nil }
            return makeAudioDevice(id: id)
        }
    }

    private func hasOutputStream(deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope:    kAudioObjectPropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == kAudioHardwareNoError && dataSize > 0
    }

    // MARK: - Default output

    public func defaultOutputDevice() throws -> AudioDevice? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var deviceID: AudioObjectID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == kAudioHardwareNoError, deviceID != kAudioObjectUnknown else { return nil }
        return makeAudioDevice(id: deviceID)
    }

    public func setDefaultOutputDevice(_ device: AudioDevice) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var deviceID = device.id
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, size, &deviceID
        )
        guard status == kAudioHardwareNoError else { throw CoreAudioError(status) }
    }

    // MARK: - Volume

    public func getVolume(for deviceID: AudioObjectID) -> Float? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope:    kAudioObjectPropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        return status == kAudioHardwareNoError ? volume : nil
    }

    public func setVolume(_ volume: Float, for deviceID: AudioObjectID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope:    kAudioObjectPropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return }
        var isSettable: DarwinBoolean = false
        AudioObjectIsPropertySettable(deviceID, &address, &isSettable)
        guard isSettable.boolValue else { return }
        var vol = Float32(volume)
        let size = UInt32(MemoryLayout<Float32>.size)
        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &vol)
    }

    // MARK: - Change observation

    public func observeChanges(handler: @escaping () -> Void) -> AnyObject {
        return ChangeToken(handler: handler)
    }

    // MARK: - Helpers

    private func makeAudioDevice(id: AudioObjectID) -> AudioDevice? {
        guard
            let name = stringProperty(id: id,
                selector: kAudioObjectPropertyName,
                scope: kAudioObjectPropertyScopeGlobal),
            let uid = stringProperty(id: id,
                selector: kAudioDevicePropertyDeviceUID,
                scope: kAudioObjectPropertyScopeGlobal)
        else { return nil }

        let rawTransport = uint32Property(id: id, selector: kAudioDevicePropertyTransportType)
        let transport = AudioDevice.TransportType(rawValue: rawTransport ?? 0) ?? .unknown
        return AudioDevice(id: id, name: name, uid: uid, transportType: transport)
    }

    private func stringProperty(
        id: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope:    scope,
            mElement:  kAudioObjectPropertyElementMain
        )
        var cfString: Unmanaged<CFString>? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &cfString)
        guard status == kAudioHardwareNoError, let raw = cfString else { return nil }
        return raw.takeRetainedValue() as String
    }

    private func uint32Property(id: AudioObjectID, selector: AudioObjectPropertySelector) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        return status == kAudioHardwareNoError ? value : nil
    }
}

// MARK: - ChangeToken

private final class ChangeToken {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        var devAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var outAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        let sysObj = AudioObjectID(kAudioObjectSystemObject)
        AudioObjectAddPropertyListener(sysObj, &devAddr, halCallback, ptr)
        AudioObjectAddPropertyListener(sysObj, &outAddr, halCallback, ptr)
    }

    deinit {
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        var devAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var outAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        let sysObj = AudioObjectID(kAudioObjectSystemObject)
        AudioObjectRemovePropertyListener(sysObj, &devAddr, halCallback, ptr)
        AudioObjectRemovePropertyListener(sysObj, &outAddr, halCallback, ptr)
    }

    fileprivate func fire() {
        DispatchQueue.main.async { [weak self] in self?.handler() }
    }
}

private func halCallback(
    _ objectID: AudioObjectID,
    _ count: UInt32,
    _ addresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let ptr = clientData else { return kAudioHardwareNoError }
    Unmanaged<ChangeToken>.fromOpaque(ptr).takeUnretainedValue().fire()
    return kAudioHardwareNoError
}

import CoreAudio

public struct CoreAudioError: Error, CustomStringConvertible {
    public let status: OSStatus
    public var description: String { "CoreAudio error: \(status)" }

    public init(_ status: OSStatus) {
        self.status = status
    }
}

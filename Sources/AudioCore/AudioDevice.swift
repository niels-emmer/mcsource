import CoreAudio

public struct AudioDevice: Sendable, Identifiable, Equatable {
    public let id: AudioObjectID
    public let name: String
    public let uid: String
    public let transportType: TransportType

    public init(id: AudioObjectID, name: String, uid: String, transportType: TransportType) {
        self.id = id
        self.name = name
        self.uid = uid
        self.transportType = transportType
    }

    public enum TransportType: UInt32, Sendable {
        case builtIn       = 0x626C746E  // 'bltn'
        case bluetooth     = 0x626C7565  // 'blue'
        case bluetoothLE   = 0x626C6561  // 'blea'
        case usb           = 0x75736220  // 'usb '
        case hdmi          = 0x68646D69  // 'hdmi'
        case displayPort   = 0x64707274  // 'dprt'
        case airPlay       = 0x61697270  // 'airp'
        case thunderbolt   = 0x7468756E  // 'thun'
        case virtual       = 0x76697274  // 'virt'
        case aggregate     = 0x67727570  // 'grup'
        case unknown       = 0

        public var defaultSFSymbol: String {
            switch self {
            case .builtIn:
                return "speaker.wave.2"
            case .bluetooth, .bluetoothLE:
                return "headphones"
            case .hdmi, .displayPort:
                return "tv"
            case .airPlay:
                return "airplayaudio"
            case .usb:
                return "hifispeaker"
            case .thunderbolt:
                return "bolt"
            case .virtual, .aggregate:
                return "waveform"
            case .unknown:
                return "speaker.slash"
            }
        }
    }
}

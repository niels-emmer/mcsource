import Foundation

public struct DeviceConfiguration: Codable, Sendable, Equatable {
    public var customName: String
    public var sfSymbol: String
    public var isEnabled: Bool
    public var isInPair: Bool
    public var savedVolume: Float?
    /// Last HAL device name seen while the device was live; used as label when offline.
    public var lastKnownName: String

    public init(
        customName: String = "",
        sfSymbol: String = "",
        isEnabled: Bool = true,
        isInPair: Bool = false,
        savedVolume: Float? = nil,
        lastKnownName: String = ""
    ) {
        self.customName     = customName
        self.sfSymbol       = sfSymbol
        self.isEnabled      = isEnabled
        self.isInPair       = isInPair
        self.savedVolume    = savedVolume
        self.lastKnownName  = lastKnownName
    }

    // Custom decoder: new fields default gracefully when absent (backward compat)
    public init(from decoder: Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        customName      = try c.decode(String.self, forKey: .customName)
        sfSymbol        = try c.decode(String.self, forKey: .sfSymbol)
        isEnabled       = try c.decode(Bool.self,   forKey: .isEnabled)
        isInPair        = try c.decodeIfPresent(Bool.self,   forKey: .isInPair)      ?? false
        savedVolume     = try c.decodeIfPresent(Float.self,  forKey: .savedVolume)
        lastKnownName   = try c.decodeIfPresent(String.self, forKey: .lastKnownName) ?? ""
    }
}

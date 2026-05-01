import Foundation

public struct DeviceConfiguration: Codable, Sendable, Equatable {
    /// User-visible name override; empty string means use the device's own name.
    public var customName: String
    /// SF Symbol name; empty string means use the transport-type default.
    public var sfSymbol: String
    /// Whether this device appears in the menu bar menu.
    public var isEnabled: Bool

    public init(customName: String = "", sfSymbol: String = "", isEnabled: Bool = true) {
        self.customName = customName
        self.sfSymbol   = sfSymbol
        self.isEnabled  = isEnabled
    }
}

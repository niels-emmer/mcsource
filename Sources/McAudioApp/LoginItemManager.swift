import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()
    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns true on success, false if the user needs to approve in System Settings.
    @discardableResult
    func setEnabled(_ enable: Bool) -> Bool {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }

    /// True when macOS is waiting for the user to approve in System Settings → General → Login Items.
    var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }
}

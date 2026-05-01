import AppKit
import AudioCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let provider: any AudioDeviceProviding = CoreAudioProvider()
    let store = ConfigurationStore()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(provider: provider, store: store)
    }
}

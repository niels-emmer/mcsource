import Carbon.HIToolbox
import Foundation

final class HotkeyManager {
    var onOpenMenu: (() -> Void)?
    var onTogglePair: (() -> Void)?

    private var openMenuHotKey: EventHotKeyRef?
    private var togglePairHotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventCallback,
            1, &eventType,
            selfPtr,
            &eventHandler
        )

        // ⌥⇧M — open menu
        let id1 = EventHotKeyID(signature: 0x6D636175, id: 1)  // 'mcau'
        RegisterEventHotKey(
            UInt32(kVK_ANSI_M), UInt32(optionKey | shiftKey),
            id1, GetApplicationEventTarget(), 0, &openMenuHotKey
        )

        // ⌥⇧P — toggle quick-switch pair
        let id2 = EventHotKeyID(signature: 0x6D636175, id: 2)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_P), UInt32(optionKey | shiftKey),
            id2, GetApplicationEventTarget(), 0, &togglePairHotKey
        )
    }

    deinit {
        if let ref = openMenuHotKey  { UnregisterEventHotKey(ref) }
        if let ref = togglePairHotKey { UnregisterEventHotKey(ref) }
        if let handler = eventHandler  { RemoveEventHandler(handler) }
    }
}

// Top-level C-compatible callback — captures nothing so Swift can bridge it.
private func hotkeyEventCallback(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    switch hotKeyID.id {
    case 1: manager.onOpenMenu?()
    case 2: manager.onTogglePair?()
    default: break
    }
    return noErr
}

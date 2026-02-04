import Foundation
import Carbon

final class ClipboardHotkeyCenter {

    static let shared = ClipboardHotkeyCenter()

    private struct Registration {
        let reference: EventHotKeyRef
        let carbonId: UInt32
        let hotkey: ClipboardHotkey
    }

    private var registrations: [UUID: Registration] = [:]
    private var idToItem: [UInt32: UUID] = [:]

    private var eventHandler: EventHandlerRef?
    private let hotkeySignature: UInt32 = 0x4D_44_48_4B // "MDHK"

    private var activationHandler: ((UUID) -> Void)?
    private var replacementHandler: ((UUID) -> Void)?

    private var nextHotkeyId: UInt32 = 1

    private init() {
        installEventHandler()
    }

    func setHandlers(onActivate: @escaping (UUID) -> Void, onReplace: @escaping (UUID) -> Void) {
        activationHandler = onActivate
        replacementHandler = onReplace
    }

    func register(_ hotkey: ClipboardHotkey, for itemId: UUID) {
        unregister(itemId: itemId)

        // Remove existing assignment if the combination is already used by another item.
        if let conflict = registrations.first(where: { $0.value.hotkey == hotkey }) {
            unregister(itemId: conflict.key)
            replacementHandler?(conflict.key)
        }

        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: hotkeySignature, id: nextHotkeyId)

        let status = RegisterEventHotKey(hotkey.keyCode,
                                         hotkey.carbonModifiers,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &hotKeyRef)

        guard status == noErr, let hotKeyRef else { return }

        registrations[itemId] = Registration(reference: hotKeyRef,
                                             carbonId: hotKeyID.id,
                                             hotkey: hotkey)
        idToItem[hotKeyID.id] = itemId
        nextHotkeyId += 1
    }

    func unregister(itemId: UUID) {
        guard let registraton = registrations[itemId] else { return }
        UnregisterEventHotKey(registraton.reference)
        idToItem.removeValue(forKey: registraton.carbonId)
        registrations.removeValue(forKey: itemId)
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetEventDispatcherTarget(),
                            { (_, event, userData) -> OSStatus in
                                guard let event = event,
                                      let userData = userData else { return noErr }

                                let center = Unmanaged<ClipboardHotkeyCenter>.fromOpaque(userData).takeUnretainedValue()
                                return center.handle(event: event)
                            },
                            1,
                            &eventSpec,
                            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                            &eventHandler)
    }

    private func handle(event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(event,
                                       UInt32(kEventParamDirectObject),
                                       UInt32(typeEventHotKeyID),
                                       nil,
                                       MemoryLayout.size(ofValue: hotKeyID),
                                       nil,
                                       &hotKeyID)

        guard status == noErr,
              hotKeyID.signature == hotkeySignature,
              let itemId = idToItem[hotKeyID.id] else {
            return noErr
        }

        activationHandler?(itemId)
        return noErr
    }
}

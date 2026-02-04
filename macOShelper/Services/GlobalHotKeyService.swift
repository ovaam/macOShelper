import Foundation
internal import AppKit
import Carbon
import ApplicationServices

final class GlobalHotKeyService {
    static let shared = GlobalHotKeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotkeySignature: UInt32 = 0x4D_44_48_4B // "MDHK"
    private var activationHandler: (() -> Void)?
    private var currentHotkeyId: UInt32 = 0

    private var nextHotkeyId: UInt32 = 1

    private init() {
        installEventHandler()
    }

    func registerHotKey(keyCode: UInt32 = 49, modifiers: UInt32 = 3, callback: @escaping () -> Void) {
        unregisterHotKey()

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        guard AXIsProcessTrustedWithOptions(options as CFDictionary) else {
            return
        }

        activationHandler = callback

        var hotKeyRef: EventHotKeyRef?
        currentHotkeyId = nextHotkeyId
        let hotKeyID = EventHotKeyID(signature: hotkeySignature, id: currentHotkeyId)

        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &hotKeyRef)

        guard status == noErr, let hotKeyRef else {
            return
        }

        self.hotKeyRef = hotKeyRef
        nextHotkeyId += 1
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        activationHandler = nil
        currentHotkeyId = 0
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetEventDispatcherTarget(),
                            { (_, event, userData) -> OSStatus in
                                guard let event = event,
                                      let userData = userData else { return noErr }

                                let service = Unmanaged<GlobalHotKeyService>.fromOpaque(userData).takeUnretainedValue()
                                return service.handle(event: event)
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
              hotKeyID.id == currentHotkeyId else {
            return noErr
        }

        DispatchQueue.main.async { [weak self] in
            self?.activationHandler?()
        }
        return noErr
    }

    var isRegistered: Bool {
        return hotKeyRef != nil
    }

    deinit {
        unregisterHotKey()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}

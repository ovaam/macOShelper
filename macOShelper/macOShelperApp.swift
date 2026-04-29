//
//  macOShelperApp.swift
//  macOShelper
//
//  Created by Малова Олеся on 04.02.2026.
//

import SwiftUI
internal import AppKit
import Carbon
import ApplicationServices

@main
struct macOShelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = CommandRegistry.shared
        _ = QuickLauncherWindow.shared

        // Глобальная hotkey для лаунчера работает через Carbon и не должна блокироваться
        // проверкой Accessibility (она нужна другим функциям, напр. симуляции ввода).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.registerHotKey()
        }

        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessibilityEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.registerHotKey()
            }
        } else {
            let hasSeenPrompt = UserDefaults.standard.bool(forKey: "hasSeenAccessibilityPrompt")
            
            if !hasSeenPrompt {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let alert = NSAlert()
                    alert.messageText = "Требуются разрешения Accessibility"
                    alert.informativeText = "MacDuck нуждается в разрешениях Accessibility для работы глобальных горячих клавиш. Пожалуйста, разрешите доступ в Системных настройках."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Открыть Настройки")
                    alert.addButton(withTitle: "Позже")
                    
                    let response = alert.runModal()
                    
                    UserDefaults.standard.set(true, forKey: "hasSeenAccessibilityPrompt")
                    
                    if response == .alertFirstButtonReturn {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        // Регистрируем hotkey даже без Accessibility (она не требуется для Carbon hotkeys).
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !GlobalHotKeyService.shared.isRegistered {
            registerHotKey()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyService.shared.unregisterHotKey()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    func applicationWillHide(_ notification: Notification) {
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    private func registerHotKey() {
        let keyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 ?? 49
        let modifiers = normalizeCarbonModifiers(UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32)
        
        GlobalHotKeyService.shared.registerHotKey(
            keyCode: keyCode,
            modifiers: modifiers,
            callback: {
                QuickLauncherWindow.shared.toggle()
            }
        )
    }

    /// Ранние версии могли сохранять неверную маску модификаторов (например `3`).
    /// Carbon ожидает биты вроде 0x0100 (⌘), 0x0800 (⌥), 0x1000 (⌃), 0x0200 (⇧).
    private func normalizeCarbonModifiers(_ raw: UInt32?) -> UInt32 {
        let fallback: UInt32 = KeyboardModifiers.cmdKey | KeyboardModifiers.optionKey // ⌘⌥ + Space

        guard let raw else { return fallback }

        // Если попалось маленькое число (< cmdKey), это почти наверняка старый/неверный формат.
        if raw < KeyboardModifiers.cmdKey {
            UserDefaults.standard.set(fallback, forKey: "hotkeyModifiers")
            return fallback
        }
        return raw
    }
}

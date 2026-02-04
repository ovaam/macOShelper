import Foundation
internal import AppKit

enum ShortcutCreator {

    static func createShortcutForFocusOn() {
        copyToClipboard("Pomodoro On") // кладём имя
        openCreateShortcut()
    }

    static func createShortcutForFocusOff() {
        copyToClipboard("Pomodoro Off")
        openCreateShortcut()
    }

    private static func openCreateShortcut() {
        if let url = URL(string: "shortcuts://create-shortcut") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

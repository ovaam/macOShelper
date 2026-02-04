import Cocoa
import SwiftUI

final class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var panel: NSPanel?
    
    func show() {
        if let w = panel {
            if w.isMiniaturized { w.deminiaturize(nil) }
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = NSHostingView(rootView: FloatingTimerWindow())

        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 600, width: 220, height: 160),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pomodoro"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.isOpaque = true
        window.backgroundColor = NSColor(Color.blackApp)

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel = window
    }

    func restore() {
        guard let w = panel else { show(); return }
        if w.isMiniaturized { w.deminiaturize(nil) }
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        panel?.close()
        panel = nil
    }
}

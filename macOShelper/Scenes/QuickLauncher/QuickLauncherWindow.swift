internal import AppKit
import SwiftUI

class QuickLauncherWindow: NSWindow {
    static let shared = QuickLauncherWindow()
    private var clickOutsideMonitor: Any?
    
    private init() {
        let screenRect = NSScreen.main?.frame ?? .zero
        let windowSize = NSSize(width: 580, height: 360)
        let windowRect = NSRect(
            x: screenRect.midX - windowSize.width / 2,
            y: screenRect.midY + 100,
            width: windowSize.width,
            height: windowSize.height
        )
        
        super.init(
            contentRect: windowRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        acceptsMouseMovedEvents = true
        minSize = NSSize(width: 400, height: 300)
        maxSize = NSSize(width: 1000, height: 800)
        hidesOnDeactivate = false

        DispatchQueue.main.async {
            let hostingView = NSHostingView(rootView: QuickLauncherView())
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.wantsLayer = true
            hostingView.layer?.cornerRadius = 10
            hostingView.layer?.masksToBounds = true
            self.contentView = hostingView

            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor)
            ])
        }
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    func show() {
        guard let contentView = self.contentView else {
            return
        }
        
        alphaValue = 0.0
        orderFrontRegardless()
        makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.makeKey()
        }

        startMonitoringClicksOutside()
    }
    
    func hide() {
        stopMonitoringClicksOutside()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1.0
        })
    }
    
    func toggle() {
        if isVisible && alphaValue > 0.5 {
            hide()
        } else {
            show()
        }
    }
    
    private func startMonitoringClicksOutside() {
        stopMonitoringClicksOutside()
        
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            
            let clickLocation = event.locationInWindow
            let windowFrame = self.frame
            
            let clickInWindow = NSPointInRect(NSEvent.mouseLocation, windowFrame)
            
            if !clickInWindow {
                DispatchQueue.main.async {
                    self.hide()
                }
            }
        }
    }
    
    private func stopMonitoringClicksOutside() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
    
    deinit {
        stopMonitoringClicksOutside()
    }
}

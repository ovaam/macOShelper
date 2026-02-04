internal import AppKit

extension NSWindow {
    @objc func toggleSidebar(_ sender: Any?) {
        let selector = #selector(NSSplitViewController.toggleSidebar(_:))
        firstResponder?.tryToPerform(selector, with: sender)
    }
}

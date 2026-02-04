import Foundation
internal import AppKit

class AppActionCommand: LauncherCommand {
    let id: String
    let name: String
    let keywords: [String]
    let description: String
    let icon: String
    let appIcon: NSImage? = nil
    private let action: () -> Void
    
    init(id: String, name: String, keywords: [String], description: String, icon: String, action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.keywords = keywords
        self.description = description
        self.icon = icon
        self.action = action
    }
    
    func execute() {
        action()
    }
}


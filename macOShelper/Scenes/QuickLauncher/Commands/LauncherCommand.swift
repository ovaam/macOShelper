import Foundation
internal import AppKit

protocol LauncherCommand {
    var id: String { get }
    var name: String { get }
    var keywords: [String] { get }
    var description: String { get }
    var icon: String { get }
    var appIcon: NSImage? { get }
    
    func execute()
}


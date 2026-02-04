import Foundation
internal import AppKit

class FileCommand: LauncherCommand {
    let id: String
    let name: String
    let keywords: [String]
    let description: String
    let icon: String
    let fileURL: URL
    let appIcon: NSImage?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        
        self.name = fileURL.lastPathComponent
        self.id = fileURL.path
        
        var keywordSet: Set<String> = [name.lowercased()]
        let nameParts = name.lowercased().split(separator: " ")
        keywordSet.formUnion(nameParts.filter { $0.count > 3 }.map { String($0) })
        
        let fileExtension = fileURL.pathExtension.lowercased()
        if !fileExtension.isEmpty && fileExtension.count > 2 {
            keywordSet.insert(fileExtension)
        }
        
        self.keywords = Array(keywordSet)
        self.description = "Открыть файл"
        self.icon = "doc"
        
        self.appIcon = NSWorkspace.shared.icon(forFile: fileURL.path)
    }
    
    func execute() {
        NSWorkspace.shared.open(fileURL)
    }
}

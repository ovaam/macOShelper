import Foundation
internal import AppKit

class ApplicationCommand: LauncherCommand {
    let id: String
    let name: String
    let keywords: [String]
    let description: String
    let icon: String
    let bundleURL: URL
    let appIcon: NSImage?
    
    init(bundleURL: URL) {
        self.bundleURL = bundleURL
        
        if let bundle = Bundle(url: bundleURL),
           let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? 
                         bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.name = appName
            self.id = bundle.bundleIdentifier ?? bundleURL.lastPathComponent
        } else {
            let appName = bundleURL.deletingPathExtension().lastPathComponent
            self.name = appName
            self.id = bundleURL.lastPathComponent
        }
        
        var keywordSet: Set<String> = [name.lowercased()]
        let nameParts = name.lowercased().split(separator: " ")
        keywordSet.formUnion(nameParts.filter { $0.count > 3 }.map { String($0) })
        
        if let aliases = ApplicationCommand.appAliases[name.lowercased()] {
            keywordSet.formUnion(aliases)
        }
        
        self.keywords = Array(keywordSet)
        self.description = "Запустить приложение"
        self.icon = "app"
        
        self.appIcon = NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
    
    func execute() {
        NSWorkspace.shared.openApplication(
            at: bundleURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }
    
    private static let appAliases: [String: [String]] = [
        "safari": ["браузер", "browser", "сафари"],
        "chrome": ["хром", "google chrome", "браузер"],
        "firefox": ["файрфокс", "браузер"],
        "xcode": ["икскод", "разработка", "development"],
        "visual studio code": ["vs code", "vscode", "код", "редактор"],
        "finder": ["файлы", "files", "файловый менеджер"],
        "mail": ["почта", "email", "письма"],
        "messages": ["сообщения", "sms", "текст"],
        "calendar": ["календарь", "события", "events"],
        "notes": ["заметки", "notes", "записи"],
        "reminders": ["напоминания", "reminders", "напомнить"],
        "spotify": ["музыка", "music", "спотифай"],
        "music": ["музыка", "itunes", "айтюнс"],
        "photos": ["фото", "photos", "изображения", "images"],
        "preview": ["просмотр", "preview", "pdf"],
        "terminal": ["терминал", "terminal", "консоль", "console"],
        "iterm": ["iterm2", "терминал", "terminal"],
        "slack": ["слак", "slack", "чат", "chat"],
        "telegram": ["телеграм", "telegram", "мессенджер"],
        "discord": ["дискорд", "discord", "чат", "chat"],
        "zoom": ["зум", "zoom", "видео", "video"],
        "system settings": ["настройки", "settings", "preferences", "системные настройки"],
        "system preferences": ["настройки", "settings", "preferences", "системные настройки"]
    ]
}

import Foundation
internal import AppKit

class CommandRegistry {
    static let shared = CommandRegistry()
    
    private var commands: [LauncherCommand] = []
    
    private init() {
        scanApplications()
        scanFiles()
        registerAppActions()
    }
    
    func register(_ command: LauncherCommand) {
        commands.append(command)
    }
    
    func search(_ query: String) -> [LauncherCommand] {
        guard !query.isEmpty else {
            return commands
        }
        
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowerQuery.isEmpty else {
            return commands
        }
        
        var scoredCommands: [(command: LauncherCommand, score: Double)] = []
        scoredCommands.reserveCapacity(commands.count)
        
        for command in commands {
            let name = command.name.lowercased()
            
            var score = calculateRelevance(query: lowerQuery, text: name)
            
            if score >= 0.95 {
                scoredCommands.append((command, score))
                continue
            }
            
            for keyword in command.keywords {
                let lowerKeyword = keyword.lowercased()
                if lowerKeyword.count <= 3 {
                    continue
                }
                let kwScore = calculateRelevance(query: lowerQuery, text: lowerKeyword)
                score = max(score, kwScore * 0.6)
                
                if score >= 0.9 {
                    break
                }
            }
            
            if score >= 0.1 {
                scoredCommands.append((command, score))
            }
        }
        
        return scoredCommands.sorted { item1, item2 in
            let isApp1 = item1.command is ApplicationCommand
            let isApp2 = item2.command is ApplicationCommand
            
            if isApp1 != isApp2 {
                return isApp1
            }
            
            if abs(item1.score - item2.score) > 0.01 {
                return item1.score > item2.score
            }
            
            let name1 = item1.command.name.lowercased()
            let name2 = item2.command.name.lowercased()
            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }.map { $0.command }
    }
    
    private func calculateRelevance(query: String, text: String) -> Double {
        if text.isEmpty || query.isEmpty {
            return 0.0
        }
        
        if text == query {
            return 1.0
        }
        
        if text.hasPrefix(query) {
            return 0.95
        }
        
        if text.contains(" " + query) {
            return 0.85
        }
        
        if let range = text.range(of: query) {
            let position = text.distance(from: text.startIndex, to: range.lowerBound)
            let positionScore = 1.0 - (Double(position) / Double(max(text.count, 1))) * 0.4
            return 0.75 * positionScore
        }
        
        if query.count < 3 {
            return 0.0
        }
        
        return fuzzyMatch(query: query, text: text)
    }
    
    private func fuzzyMatch(query: String, text: String) -> Double {
        let queryChars = Array(query)
        let textChars = Array(text)
        
        var queryIndex = 0
        var textIndex = 0
        var matchPositions: [Int] = []
        
        while textIndex < textChars.count && queryIndex < queryChars.count {
            if textChars[textIndex] == queryChars[queryIndex] {
                matchPositions.append(textIndex)
                queryIndex += 1
            }
            textIndex += 1
        }
        
        if queryIndex < queryChars.count {
            return 0.0
        }
        
        let firstMatch = matchPositions[0]
        let lastMatch = matchPositions[matchPositions.count - 1]
        let span = lastMatch - firstMatch
        
        if span == queryChars.count - 1 {
            let positionScore = firstMatch == 0 ? 1.0 : max(0.0, 1.0 - Double(firstMatch) / Double(textChars.count))
            return 0.5 * positionScore
        }
        
        let compactness = Double(queryChars.count) / Double(max(span + 1, 1))
        let positionScore = firstMatch == 0 ? 1.0 : max(0.0, 1.0 - Double(firstMatch) / Double(textChars.count))
        
        if span > queryChars.count * 3 {
            return 0.0
        }
        
        let score = (compactness * 0.5 + positionScore * 0.5) * 0.4
        
        return score
    }
    
    func getAllCommands() -> [LauncherCommand] {
        return commands
    }

    
    private func scanApplications() {
        let applicationPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications",
            "/Applications/Utilities",
            "/System/Applications/Utilities"
        ]
        
        var foundBundles: Set<String> = []
        
        for path in applicationPaths {
            let url = URL(fileURLWithPath: path)
            scanDirectory(url: url, foundBundles: &foundBundles)
        }
        
        commands.sort { command1, command2 in
            return command1.name.localizedCaseInsensitiveCompare(command2.name) == .orderedAscending
        }
    }
    
    private func scanDirectory(url: URL, foundBundles: inout Set<String>) {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "app" {
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }
                
                let infoPlistPath = fileURL.appendingPathComponent("Contents/Info.plist").path
                guard FileManager.default.fileExists(atPath: infoPlistPath) else { continue }
                
                if let bundle = Bundle(url: fileURL),
                   let bundleID = bundle.bundleIdentifier {
                    if foundBundles.contains(bundleID) {
                        continue
                    }
                    foundBundles.insert(bundleID)
                }
                
                let appCommand = ApplicationCommand(bundleURL: fileURL)
                register(appCommand)
                
                enumerator.skipDescendants()
            }
        }
    }
    
    private func scanFiles() {
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        let commonPaths = [
            homeURL.appendingPathComponent("Documents"),
            homeURL.appendingPathComponent("Downloads"),
            homeURL.appendingPathComponent("Desktop")
        ]
        
        var scannedFiles = 0
        let maxFiles = 1000
        
        for pathURL in commonPaths {
            guard scannedFiles < maxFiles else { break }
            
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: pathURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }
            
            guard let enumerator = FileManager.default.enumerator(
                at: pathURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }
            
            for case let fileURL as URL in enumerator {
                guard scannedFiles < maxFiles else { break }
                
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir),
                      !isDir.boolValue else { continue }
                
                if fileURL.pathExtension == "app" {
                    continue
                }
                
                if fileURL.lastPathComponent.hasPrefix(".") {
                    continue
                }
                
                let fileCommand = FileCommand(fileURL: fileURL)
                register(fileCommand)
                scannedFiles += 1
            }
        }
    }
    
    private func registerAppActions() {
        register(AppActionCommand(
            id: "app.task.new",
            name: "Создать новую задачу",
            keywords: ["task", "задача", "создать", "новая", "добавить", "new", "add"],
            description: "Открыть форму создания задачи",
            icon: "plus.square"
        ) {
            NotificationCenter.default.post(name: .showAddTask, object: nil)
        })
        
        register(AppActionCommand(
            id: "app.task.view",
            name: "Просмотреть задачи",
            keywords: ["task", "задачи", "список", "tasks", "view"],
            description: "Перейти к списку задач",
            icon: "checklist"
        ) {
            NotificationCenter.default.post(name: .switchToTab, object: Tab.taskManager)
        })
        
        register(AppActionCommand(
            id: "app.pomodoro.start.25",
            name: "Помодоро 25 минут",
            keywords: ["pomodoro", "помодоро", "таймер", "25", "фокус", "focus"],
            description: "Запустить таймер на 25 минут",
            icon: "timer"
        ) {
            PomodoroService.shared.start(taskID: nil, taskTitle: nil, duration: 25 * 60)
            QuickLauncherWindow.shared.hide()
        })
        
        register(AppActionCommand(
            id: "app.pomodoro.start.15",
            name: "Помодоро 15 минут",
            keywords: ["pomodoro", "помодоро", "таймер", "15", "фокус", "короткий"],
            description: "Запустить таймер на 15 минут",
            icon: "timer"
        ) {
            PomodoroService.shared.start(taskID: nil, taskTitle: nil, duration: 15 * 60)
            QuickLauncherWindow.shared.hide()
        })
        
        register(AppActionCommand(
            id: "app.pomodoro.stop",
            name: "Остановить помодоро",
            keywords: ["pomodoro", "помодоро", "стоп", "остановить", "stop", "cancel"],
            description: "Остановить текущий таймер",
            icon: "stop.circle"
        ) {
            PomodoroService.shared.stop(save: true)
            QuickLauncherWindow.shared.hide()
        })
        
        register(AppActionCommand(
            id: "app.pomodoro.view",
            name: "Открыть таймер",
            keywords: ["pomodoro", "помодоро", "таймер", "время", "time"],
            description: "Перейти к таймеру помодоро",
            icon: "clock"
        ) {
            NotificationCenter.default.post(name: .switchToTab, object: Tab.timeManager)
        })
        
        register(AppActionCommand(
            id: "app.clipboard.clear",
            name: "Очистить буфер обмена",
            keywords: ["clipboard", "буфер", "очистить", "clear", "удалить"],
            description: "Удалить всю историю буфера обмена",
            icon: "trash"
        ) {
            ClipboardHistoryService.shared.clearAll()
            QuickLauncherWindow.shared.hide()
        })
        
        register(AppActionCommand(
            id: "app.clipboard.view",
            name: "Открыть буфер обмена",
            keywords: ["clipboard", "буфер", "история", "copy", "paste"],
            description: "Перейти к истории буфера обмена",
            icon: "doc.on.clipboard"
        ) {
            NotificationCenter.default.post(name: .switchToTab, object: Tab.exchangeBuffer)
        })
    }
}

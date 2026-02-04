import Foundation
internal import AppKit

class ParameterizedCommand: LauncherCommand {
    let id: String
    let name: String
    let keywords: [String]
    let description: String
    let icon: String
    let appIcon: NSImage? = nil
    let parsedCommand: ParsedCommand
    private let action: ([String]) -> Void
    
    init(parsedCommand: ParsedCommand, action: @escaping ([String]) -> Void) {
        self.parsedCommand = parsedCommand
        self.id = "param.\(parsedCommand.action).\(UUID().uuidString)"
        self.action = action
        
        switch parsedCommand.action {
        case "task.add":
            self.name = "Создать задачу: \(parsedCommand.parameters.joined(separator: " "))"
            self.keywords = ["task", "задача", "добавить"]
            self.description = "Добавить новую задачу в список"
            self.icon = "plus.square.fill"
            
        case "pomodoro.start":
            let minutes = parsedCommand.parameters.first ?? "25"
            self.name = "Запустить помодоро \(minutes) минут"
            self.keywords = ["pomodoro", "помодоро", "таймер"]
            self.description = "Запустить таймер на \(minutes) минут"
            self.icon = "timer.square.fill"
            
        default:
            self.name = parsedCommand.action
            self.keywords = []
            self.description = "Выполнить команду"
            self.icon = "command"
        }
    }
    
    func execute() {
        action(parsedCommand.parameters)
    }
}


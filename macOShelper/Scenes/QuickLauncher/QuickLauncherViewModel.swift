import Foundation
import Combine

enum CommandCategory: String {
    case all = "Все результаты"
    case actions = "Команды"
    case applications = "Приложения"
    case files = "Файлы"
}

struct GroupedCommands {
    var all: [LauncherCommand] = []
    var actions: [LauncherCommand] = []
    var applications: [LauncherCommand] = []
    var files: [LauncherCommand] = []
}

class QuickLauncherViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            UserDefaults.standard.set(searchText, forKey: "quickLauncherLastSearchText")
        }
    }
    @Published var filteredCommands: [LauncherCommand] = []
    @Published var groupedCommands: GroupedCommands = GroupedCommands()
    @Published var shouldSelectAll: Bool = false
    
    private let commandRegistry = CommandRegistry.shared
    private let commandParser = CommandParser.shared
    private let lastSearchTextKey = "quickLauncherLastSearchText"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let lastText = UserDefaults.standard.string(forKey: lastSearchTextKey) {
            searchText = lastText
            shouldSelectAll = true
        }
        
        let allCommands = commandRegistry.getAllCommands()
        filteredCommands = allCommands
        groupedCommands = groupCommands(allCommands)
        
        $searchText
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] query in
                guard let self = self else { return [] }
                
                var results = self.commandRegistry.search(query)
                
                if let parsedCommand = self.commandParser.parse(query) {
                    let paramCommand = self.createParameterizedCommand(parsedCommand)
                    results.insert(paramCommand, at: 0)
                }
                
                return results
            }
            .sink { [weak self] (commands: [LauncherCommand]) in
                guard let self = self else { return }
                self.filteredCommands = commands
                self.groupedCommands = self.groupCommands(commands)
            }
            .store(in: &cancellables)
    }
    
    func executeCommand(_ command: LauncherCommand) {
        command.execute()
    }
    
    func clearSearch() {
        searchText = ""
        UserDefaults.standard.removeObject(forKey: lastSearchTextKey)
    }
    
    private func groupCommands(_ commands: [LauncherCommand]) -> GroupedCommands {
        var grouped = GroupedCommands()
        grouped.all = commands
        
        for command in commands {
            if command is AppActionCommand || command is ParameterizedCommand {
                grouped.actions.append(command)
            } else if command is ApplicationCommand {
                grouped.applications.append(command)
            } else if command is FileCommand {
                grouped.files.append(command)
            }
        }
        
        return grouped
    }
    
    private func createParameterizedCommand(_ parsedCommand: ParsedCommand) -> ParameterizedCommand {
        switch parsedCommand.action {
        case "task.add":
            return ParameterizedCommand(parsedCommand: parsedCommand) { params in
                guard let taskTitle = params.first, !taskTitle.isEmpty else { return }
                
                let task = Task(
                    title: taskTitle,
                    priority: .medium
                )
                
                let viewModel = TaskManagerViewModel()
                viewModel.loadTasks()
                viewModel.addTask(task)
                
                QuickLauncherWindow.shared.hide()
                
                NotificationCenter.default.post(name: .switchToTab, object: Tab.taskManager)
            }
            
        case "pomodoro.start":
            return ParameterizedCommand(parsedCommand: parsedCommand) { params in
                guard let minutesStr = params.first,
                      let minutes = Int(minutesStr) else { return }
                
                let duration = TimeInterval(minutes * 60)
                PomodoroService.shared.start(taskID: nil, taskTitle: nil, duration: duration)
                
                QuickLauncherWindow.shared.hide()
            }
            
        default:
            return ParameterizedCommand(parsedCommand: parsedCommand) { _ in }
        }
    }
}

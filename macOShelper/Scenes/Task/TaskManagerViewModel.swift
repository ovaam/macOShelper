import Foundation
import SwiftUI
import Combine

class TaskManagerViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filterPriority: Task.Priority?
    @Published var editingTask: Task?
    
    private let tasksKey = "savedTasks"
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let savedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = savedTasks
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    func filteredTasks(_ searchText: String) -> [Task] {
        var filtered = tasks
        
        // Filter by priority
        if let priority = filterPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort: overdue first, then by priority, then by date
        return filtered.sorted { task1, task2 in
            let isTask1Overdue = task1.dueDate.map { $0 < Date() && !task1.isCompleted } ?? false
            let isTask2Overdue = task2.dueDate.map { $0 < Date() && !task2.isCompleted } ?? false
            
            if isTask1Overdue != isTask2Overdue {
                return isTask1Overdue && !isTask2Overdue
            }
            
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            
            return task1.createdAt > task2.createdAt
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            let originalTask = tasks[index]
            var updated = updatedTask
            // Preserve original createdAt and update updatedAt
            updated.createdAt = originalTask.createdAt
            updated.updatedAt = Date()
            tasks[index] = updated
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = tasks[index]
            updated.isCompleted.toggle()
            updated.updatedAt = Date()
            tasks[index] = updated
            saveTasks()
        }
    }
}

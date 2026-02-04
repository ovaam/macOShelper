import Foundation
import SwiftUI

// MARK: - Task Model
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: Priority
    var tags: [String]
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var estimatedDuration: TimeInterval?
    
    enum Priority: Int, CaseIterable, Codable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
        
        var displayName: String {
            switch self {
            case .low: return "Низкий"
            case .medium: return "Средний"
            case .high: return "Высокий"
            case .critical: return "Критический"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var systemImage: String {
            switch self {
            case .low: return "arrow.down"
            case .medium: return "equal"
            case .high: return "arrow.up"
            case .critical: return "exclamationmark.triangle"
            }
        }
    }
    
    init(id: UUID = UUID(),
         title: String,
         description: String? = nil,
         dueDate: Date? = nil,
         priority: Priority = .medium,
         tags: [String] = [],
         isCompleted: Bool = false,
         estimatedDuration: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.tags = tags
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
        self.estimatedDuration = estimatedDuration
    }
}

// MARK: - Quick Launcher Command
struct CommandSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let command: String
    let icon: String
    let action: () -> Void
}

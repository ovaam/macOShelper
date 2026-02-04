import SwiftUI

struct TaskManagerView: View {
    @StateObject private var viewModel = TaskManagerViewModel()
    @State private var showingAddTask = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .background(Color.blackApp)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView { task in
                viewModel.addTask(task)
            }
        }
        .onAppear {
            viewModel.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTask)) { _ in
            showingAddTask = true
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                SearchBar(text: $searchText, placeholder: "Поиск задач...")
                
                Spacer()
                
                Menu {
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        Button {
                            viewModel.filterPriority = priority
                        } label: {
                            HStack {
                                Text(priority.displayName)
                                if viewModel.filterPriority == priority {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("Сбросить фильтры") {
                        viewModel.filterPriority = nil
                    }
                } label: {
                    Label("Фильтры", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Button("Добавить задачу") {
                    showingAddTask = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
            if viewModel.filterPriority != nil || !searchText.isEmpty {
                HStack {
                    FilterChips(viewModel: viewModel, searchText: searchText)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private var contentView: some View {
        Group {
            if viewModel.filteredTasks(searchText).isEmpty {
                emptyStateView
            } else {
                tasksListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondaryTextApp)
            
            Text("Нет задач")
                .font(.title2)
                .foregroundColor(.mainTextApp)
            
            if searchText.isEmpty && viewModel.filterPriority == nil {
                Text("Создайте свою первую задачу")
                    .foregroundColor(.secondaryTextApp)
                
                Button("Добавить задачу") {
                    showingAddTask = true
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("Попробуйте изменить параметры поиска")
                    .foregroundColor(.secondaryTextApp)
                
                Button("Сбросить фильтры") {
                    searchText = ""
                    viewModel.filterPriority = nil
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var tasksListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredTasks(searchText)) { task in
                    TaskRowView(task: task) {
                        viewModel.toggleTaskCompletion(task)
                    } onEdit: {
                        viewModel.editingTask = task
                    } onDelete: {
                        viewModel.deleteTask(task)
                    }
                    .contextMenu {
                        Button("Завершить") {
                            viewModel.toggleTaskCompletion(task)
                        }
                        
                        Button("Редактировать") {
                            viewModel.editingTask = task
                        }
                        
                        Divider()
                        
                        Button("Удалить", role: .destructive) {
                            viewModel.deleteTask(task)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $viewModel.editingTask) { task in
            EditTaskView(task: task) { updatedTask in
                viewModel.updateTask(updatedTask)
            }
        }
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryTextApp)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryTextApp)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color.lightGrayApp.opacity(0.5))
        .cornerRadius(8)
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .greenAccent : .secondaryTextApp)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.mainTextApp)
                        .strikethrough(task.isCompleted)
                        .opacity(task.isCompleted ? 0.6 : 1.0)
                    
                    Spacer()
                    
                    // Priority
                    HStack(spacing: 4) {
                        Image(systemName: task.priority.systemImage)
                            .font(.caption)
                        Text(task.priority.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(task.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(task.priority.color.opacity(0.2))
                    .cornerRadius(4)
                }
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondaryTextApp)
                        .lineLimit(2)
                }
                
                // Tags and due date
                HStack {
                    if !task.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(task.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.greenAccent.opacity(0.3))
                                        .foregroundColor(.greenAccent)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(dueDate < Date() && !task.isCompleted ? .redAccent : .secondaryTextApp)
                    }
                }
            }
            
            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    Button("Редактировать") {
                        onEdit()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Удалить") {
                        onDelete()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.cardBackgroundApp)
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FilterChips: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    let searchText: String
    
    var body: some View {
        HStack(spacing: 8) {
            if let priority = viewModel.filterPriority {
                HStack(spacing: 4) {
                    Text("Приоритет: \(priority.displayName)")
                    Button {
                        viewModel.filterPriority = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priority.color.opacity(0.2))
                .foregroundColor(priority.color)
                .cornerRadius(8)
            }
            
            if !searchText.isEmpty {
                HStack(spacing: 4) {
                    Text("Поиск: \(searchText)")
                    Button {
                        // Clear search through binding in parent
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.greenAccent.opacity(0.2))
                .foregroundColor(.greenAccent)
                .cornerRadius(8)
            }
        }
    }
}

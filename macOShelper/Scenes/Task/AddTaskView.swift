import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Task) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority: Task.Priority = .medium
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var estimatedDuration: Double = 25
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Новая задача")
                .font(.title2)
                .foregroundColor(.mainTextApp)
            
            Form {
                Section {
                    TextField("Название задачи", text: $title)
                    TextField("Описание", text: $description)
                }
                
                Section("Приоритет") {
                    Picker("Приоритет", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Срок выполнения") {
                    Toggle("Установить срок", isOn: $hasDueDate.animation())
                    
                    if hasDueDate {
                        DatePicker("Выполнить до", selection: $dueDate, in: Date()...)
                    }
                }
                
                Section("Теги") {
                    TagInputView(tags: $tags, newTag: $newTag)
                }
                
                Section("Оценка времени") {
                    Stepper("\(Int(estimatedDuration)) минут", value: $estimatedDuration, in: 5...240, step: 5)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button("Создать") {
                    let task = Task(
                        title: title,
                        description: description.isEmpty ? nil : description,
                        dueDate: hasDueDate ? dueDate : nil,
                        priority: priority,
                        tags: tags,
                        estimatedDuration: estimatedDuration * 60
                    )
                    onSave(task)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let task: Task
    let onSave: (Task) -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: Task.Priority
    @State private var tags: [String]
    @State private var newTag: String
    @State private var estimatedDuration: Double
    @State private var isCompleted: Bool
    
    init(task: Task, onSave: @escaping (Task) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _priority = State(initialValue: task.priority)
        _tags = State(initialValue: task.tags)
        _newTag = State(initialValue: "")
        _estimatedDuration = State(initialValue: (task.estimatedDuration ?? 1500) / 60)
        _isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Редактировать задачу")
                .font(.title2)
                .foregroundColor(.mainTextApp)
            
            Form {
                Section {
                    TextField("Название задачи", text: $title)
                    TextField("Описание", text: $description)
                }
                
                Section {
                    Toggle("Выполнена", isOn: $isCompleted)
                }
                
                Section("Приоритет") {
                    Picker("Приоритет", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Срок выполнения") {
                    Toggle("Установить срок", isOn: $hasDueDate.animation())
                    
                    if hasDueDate {
                        DatePicker("Выполнить до", selection: $dueDate, in: Date()...)
                    }
                }
                
                Section("Теги") {
                    TagInputView(tags: $tags, newTag: $newTag)
                }
                
                Section("Оценка времени") {
                    Stepper("\(Int(estimatedDuration)) минут", value: $estimatedDuration, in: 5...240, step: 5)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button("Сохранить") {
                    var updatedTask = task
                    updatedTask.title = title
                    updatedTask.description = description.isEmpty ? nil : description
                    updatedTask.dueDate = hasDueDate ? dueDate : nil
                    updatedTask.priority = priority
                    updatedTask.tags = tags
                    updatedTask.isCompleted = isCompleted
                    updatedTask.estimatedDuration = estimatedDuration * 60
                    updatedTask.updatedAt = Date()
                    
                    onSave(updatedTask)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct TagInputView: View {
    @Binding var tags: [String]
    @Binding var newTag: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Новый тег", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Добавить") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                
                                Button {
                                    removeTag(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.greenAccent.opacity(0.3))
                            .foregroundColor(.greenAccent)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

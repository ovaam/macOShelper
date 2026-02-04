import SwiftUI

struct TimeManagerView: View {

    @ObservedObject private var service = PomodoroService.shared
    @StateObject private var taskVM = TaskManagerViewModel()
    @State private var selectedTaskID: UUID? = nil

    @State private var taskTitle: String = ""
    @State private var selectedMinutes: Int = 25
    
    @State private var showingFocusOnAlert = false
    @State private var showingFocusOffAlert = false
    
    @AppStorage("focusOnConfigured") private var focusOnConfigured = false
    @AppStorage("focusOffConfigured") private var focusOffConfigured = false

    @State private var showStatsChart = false
    @State private var showCustomTimeSheet = false
    @State private var customMinutesInput: String = ""

    private let presets = [15, 25, 45]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection()

            timerSection()
                .padding()
                .background(Color.lightGrayApp)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            controlsSection()
            
            statsSection()
                .frame(maxWidth: .infinity)
            
            focusSetupSection()
        }
        .padding(20)
        .background(Color.blackApp)
        .navigationTitle(Tab.timeManager.rawValue)
        .sheet(isPresented: $showCustomTimeSheet) {
            customTimeInputSheet()
        }
        .alert("Настройка включения фокусирования",
               isPresented: $showingFocusOnAlert) {
            Button("Открыть Команды") {
                ShortcutCreator.createShortcutForFocusOn()
                focusOnConfigured = true
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            focusOnAlertMessage()
        }

        .alert("Настройка отключения фокусирования",
               isPresented: $showingFocusOffAlert) {
            Button("Открыть Команды") {
                ShortcutCreator.createShortcutForFocusOff()
                focusOffConfigured = true
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            focusOffAlertMessage()
        }
    }

    // MARK: UI
    
    private func headerSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Фокус-задача")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)
            
            Picker("", selection: $selectedTaskID) {
                Text("Без задачи").tag(UUID?.none)
                ForEach(taskVM.tasks) { task in
                    Text(task.title).tag(Optional(task.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .labelsHidden()
            .onAppear { taskVM.loadTasks() }
            .onChange(of: selectedTaskID) { oldValue, newValue in
                if let id = newValue,
                   let task = taskVM.tasks.first(where: { $0.id == id }),
                   let est = task.estimatedDuration {
                    let minutes = max(1, Int(est / 60))
                    selectedMinutes = minutes
                }
            }

            Text("Длительность")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)

            customSegmentControl()
        }
    }

    private func customSegmentControl() -> some View {
        HStack(spacing: 0) {
            ForEach(presets, id: \.self) { m in
                segmentButton(label: "\(m) мин", isSelected: selectedMinutes == m) {
                    selectedMinutes = m
                }
            }

            segmentButton(label: "Свое", isSelected: !presets.contains(selectedMinutes)) {
                showCustomTimeSheet.toggle()
            }
        }
        .frame(height: 32)
        .background(Color.lightGrayApp)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func segmentButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Font.custom("HSESans-Regular", size: 14))
                .foregroundColor(isSelected ? .white : .secondaryTextApp)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Color.grayApp : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func timerSection() -> some View {
        VStack(spacing: 8) {
            Text(formattedRemaining())
                .font(Font.custom("HSESans-Bold", size: 48))
                .foregroundColor(.mainTextApp)

            if service.isPaused() {
                Text("Пауза")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            } else if service.isRunning() {
                Text("В фокусе…")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            } else {
                Text("Готов к старту")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func controlsSection() -> some View {
        HStack(spacing: 12) {
            if service.isRunning() || service.isPaused() {
                Button(service.isPaused() ? "Продолжить" : "Пауза") {
                    service.togglePause()
                }
                .applySecondaryButton()

                Button("Стоп") {
                    service.stop()
                }
                .applyPrimaryButton()

            } else {
                Button("Старт") {
                    startTimer()
                }
                .applyPrimaryButton()
            }

            Spacer()
        }
    }

    private func statsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Статистика")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)

            VStack(spacing: 12) {
                HStack(spacing: 24) {
                    statTile(title: "Сегодня", seconds: service.totalToday())
                    statTile(title: "7 дней", seconds: service.totalLast7Days())
                }

                // График за неделю
                if showStatsChart {
                    ProductivityChart(data: service.dailyStatsLast7Days())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .frame(height: 120)
                        .padding(.top, 8)
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.25)) {
                    showStatsChart = hovering
                }
            }
        }
        .padding(.top, 12)
    }

    private func statTile(title: String, seconds: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Font.custom("HSESans-Regular", size: 12))
                .foregroundColor(.secondaryTextApp)
            Text(formatHHMM(from: seconds))
                .font(Font.custom("HSESans-Bold", size: 20))
                .foregroundColor(.mainTextApp)
        }
        .padding(12)
        .frame(width: 150, alignment: .leading)
        .background(Color.lightGrayApp)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func focusSetupSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Режим фокусирования")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)
                .padding(.top, 12)

            if !focusOnConfigured || !focusOffConfigured {
                // Вид для первоначальной настройки
                HStack(spacing: 12) {
                    Button("Настроить включение") {
                        showingFocusOnAlert = true
                        focusOnConfigured = true
                    }
                    .applyPrimaryButton()

                    Button("Настроить отключение") {
                        showingFocusOffAlert = true
                        focusOffConfigured = true
                    }
                    .applyPrimaryButton()
                }

                Text("Нужно настроить один раз, чтобы фокус включался и выключался автоматически.")
                    .font(Font.custom("HSESans-Regular", size: 12))
                    .foregroundColor(.secondaryTextApp)
                    .padding(.top, 4)

            } else {
                // Компактный режим после настройки
                VStack(alignment: .leading, spacing: 6) {
                    Button("Перенастроить") {
                        focusOnConfigured = false
                        focusOffConfigured = false
                    }
                    .applySecondaryButton()
                }
            }
        }
    }

    // MARK: Custom Time Sheet

    private func customTimeInputSheet() -> some View {
        VStack(spacing: 16) {
            Text("Выберите длительность")
                .font(Font.custom("HSESans-SemiBold", size: 16))
                .foregroundColor(.mainTextApp)

            TextField("Минуты", text: $customMinutesInput)
                .textFieldStyle(.roundedBorder)
                .font(Font.custom("HSESans-Regular", size: 14))
                .frame(width: 120)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Отмена") {
                    showCustomTimeSheet = false
                }
                .applySecondaryButton()

                Button("Сохранить") {
                    if let minutes = Int(customMinutesInput), minutes > 0 {
                        selectedMinutes = minutes
                    }
                    showCustomTimeSheet = false
                }
                .applyPrimaryButton()
            }
        }
        .padding(24)
        .background(Color.blackApp)
        .frame(width: 250)
    }

    // MARK: Actions

    private func startTimer() {
        let duration = TimeInterval(selectedMinutes * 60)
        let selectedTask = taskVM.tasks.first(where: { $0.id == selectedTaskID })
        service.start(taskID: selectedTask?.id, taskTitle: selectedTask?.title, duration: duration)
    }
    
    // MARK: – Focus Setup Alerts Text

    private func focusOnAlertMessage() -> Text {
        Text("""
    Сейчас откроется приложение «Команды».

    1) Вставьте название:
       нажмите ⌘V (название «Pomodoro On» уже скопировано).

    2) Найдите и добавьте действие:
       «Вкл./выкл. фокусирование».

    3) Выберите:
       «Вкл.» → до «Выключения».

    Затем можете просто закрыть нажмите приложение «Команды».
    """)
    }

    private func focusOffAlertMessage() -> Text {
        Text("""
    Сейчас откроется приложение «Команды».

    1) Вставьте название:
       нажмите ⌘V (название «Pomodoro Off» уже скопировано).

    2) Найдите и добавьте действие:
       «Вкл./выкл. фокусирование».

    3) Выберите:
       «выключить».

    Затем можете просто закрыть нажмите приложение «Команды».
    """)
    }


    // MARK: Time formatting

    private func formattedRemaining() -> String {
        if service.isRunning() || service.isPaused() {
            let t = service.secondsRemaining()
            return String(format: "%02d:%02d", t / 60, t % 60)
        }
        return String(format: "%02d:00", selectedMinutes)
    }

    private func formatHHMM(from seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60

        if h > 0 {
            return String(format: "%02d ч %02d мин", h, m)
        } else {
            return String(format: "%02d мин", m)
        }
    }
}

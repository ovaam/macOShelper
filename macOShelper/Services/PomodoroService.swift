import Foundation
import UserNotifications
import Combine
internal import AppKit

final class PomodoroService: ObservableObject {
    
    static let shared = PomodoroService()

    @Published private(set) var state: RunningPomodoroState?

    private let stats = StatsStorage.shared

    private var timer: AnyCancellable?

    func start(taskID: UUID?, taskTitle: String?, duration: TimeInterval) {
        // Включаем фокус перед стартом сессии
        ShortcutRunner.focusOn()

        state = RunningPomodoroState(
            taskID: taskID,
            taskTitle: taskTitle?.isEmpty == true ? nil : taskTitle,
            totalDuration: duration,
            remaining: duration,
            startedAt: Date(),
            isPaused: false
        )

        // Запускаем раз в секунду
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
        // Показываем мини-окно с таймером
        FloatingWindowManager.shared.show()
    }

    func togglePause() {
        guard var s = state else { return }
        s.isPaused.toggle()
        state = s

        if s.isPaused {
            // При паузе просто прекращаем тикать
            timer?.cancel()
            timer = nil
        } else {
            // Возврат к тикам
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
        }
    }

    // Полная остановка
    func stop(save: Bool = true) {
        // Выключаем фокус при остановке вручную
        ShortcutRunner.focusOff()
        
        // Закрываем мини-окно при ручной остановке
        FloatingWindowManager.shared.close()

        timer?.cancel()
        timer = nil

        defer { state = nil }

        guard save, let s = state else { return }
        // Записываем завершенную сессию в статистику
        let finished = Date()
        let session = PomodoroSession(
            id: UUID(),
            taskID: s.taskID,
            taskTitle: s.taskTitle,
            totalDuration: s.totalDuration - max(0, s.remaining),
            startedAt: s.startedAt,
            finishedAt: finished
        )
        stats.append(session: session)
    }

    // Тик таймера
    private func tick() {
        guard var s = state, !s.isPaused else { return }
        s.remaining = max(0, s.remaining - 1)
        state = s

        if s.remaining <= 0 {
            // Снимаем фокус при завершении таймера
            ShortcutRunner.focusOff()

            // Автостоп и запись статистики
            stop(save: true)

            // Закрываем мини-окно с таймером
            FloatingWindowManager.shared.close()

            // Даем macOS время выключить режим "Не беспокоить", чтобы уведомление не было заглушено
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showCompletionNotification()
            }
        }
    }

    // MARK: – Быстрые геттеры для UI

    func secondsRemaining() -> Int {
        Int(state?.remaining ?? 0)
    }

    func totalSeconds() -> Int {
        Int(state?.totalDuration ?? 0)
    }

    func isRunning() -> Bool {
        state != nil && state?.isPaused == false
    }

    func isPaused() -> Bool {
        state?.isPaused ?? false
    }

    // Доступ к статистике
    func totalToday() -> TimeInterval { stats.totalToday() }
    func totalLast7Days() -> TimeInterval { stats.totalLast7Days() }
    
    // MARK: – Уведомления
    
    private func showCompletionNotification() {
        // Разрешение на уведомления (однократный запрос)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            DispatchQueue.main.async {
                let messages = [
                    "Время вышло. Сделай паузу ☕️",
                    "Фокус-сессия завершена 🌿",
                    "Отличная работа! 🔥",
                    "Ты справился! 💪 Отдохни немного.",
                    "Пора немного размяться 🕺",
                    "Теперь перерыв! Ты это заслужил 😎",
                    "Молодец, так держать! 🌟",
                    "Время взглянуть в окно 🌤️",
                    "Отличная работа, чемпион 🏆",
                    "Завершено ✅ Теперь немного отдыха.",
                    "Ты — машина продуктивности 🤖 Сделай перерыв!",
                    "Сессия закрыта 🎯 Можешь гордиться собой.",
                    "Помидорчик сварился 🍅 Отдохни!",
                    "Теперь можно TikTok, но только чуть-чуть 😉",
                    "Пора зарядиться энергией ⚡️"
                ]
                
                let content = UNMutableNotificationContent()
                content.title = "Pomodoro завершено"
                content.body = messages.randomElement() ?? "Сессия завершена"
                
                // Звук уведомления
                content.sound = UNNotificationSound(named: UNNotificationSoundName("Ping"))
                
                // Создаём и добавляем уведомление
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
    
    // Возвращает данные по дням недели для графика
    func dailyStatsLast7Days() -> [TimeInterval] {
        stats.last7DaysBreakdown()
    }
}

import Foundation

final class StatsStorage {
    static let shared = StatsStorage()
    private(set) var sessions: [PomodoroSession] = []

    private let defaults = UserDefaults.standard
    private let key = "pomodoro.sessions.v1"

    // Сохраненные завершенные сессии
    func loadAll() -> [PomodoroSession] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([PomodoroSession].self, from: data)
        } catch {
            return []
        }
    }

    // Перезапись всего списка
    private func saveAll(_ sessions: [PomodoroSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            defaults.set(data, forKey: key)
        } catch { }
    }

    // Добавить одну завершенную сессию
    func append(session: PomodoroSession) {
        var list = loadAll()
        list.append(session)
        saveAll(list)
        sessions = list
    }

    // Суммарное фокус-время за сегодня
    func totalToday(now: Date = .init()) -> TimeInterval {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? now
        return loadAll()
            .filter { $0.finishedAt >= start && $0.finishedAt < end }
            .reduce(0) { $0 + $1.totalDuration }
    }

    // Суммарное фокус-время за последние 7 дней
    func totalLast7Days(now: Date = .init()) -> TimeInterval {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
        return loadAll()
            .filter { $0.finishedAt >= start && $0.finishedAt < end }
            .reduce(0) { $0 + $1.totalDuration }
    }
    
    // Возвращает количество затраченного времени (в секундах) по дням за последние 7 дней
    func last7DaysBreakdown() -> [TimeInterval] {
        let calendar = Calendar.current
        let sessions = loadAll()
        
        var result: [TimeInterval] = []
        let today = calendar.startOfDay(for: Date())
        
        for i in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -i, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day)
            else { continue }
            
            let total = sessions
                .filter { $0.startedAt >= day && $0.startedAt < nextDay }
                .reduce(0) { $0 + $1.totalDuration }
            
            result.append(total)
        }
        return result
    }
}

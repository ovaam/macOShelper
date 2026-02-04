import Foundation
internal import AppKit

enum ShortcutRunner {

    // Имена команд. Пользователь создаёт их вручную в Командах (Shortcuts)
    static let onName = "Pomodoro On"
    static let offName = "Pomodoro Off"

    // Запуск команды по имени
    static func run(_ name: String) {
        // Кодировка имени для командной строки
        let process = Process()
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["run", name]

        // Перенаправляем вывод, чтобы не мешал интерфейсу
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Запуск команды без открытия окна "Команды"
        process.launch()
    }

    static func focusOn()  { run(onName) }
    static func focusOff() { run(offName) }
}

import Foundation

struct ParsedCommand {
    let action: String
    let parameters: [String]
    var fullText: String
}

class CommandParser {
    static let shared = CommandParser()
    
    private let commandPatterns: [CommandPattern] = [
        CommandPattern(
            keywords: ["task", "задача", "задачу"],
            actions: ["add", "new", "create", "добавить", "создать", "новая"],
            handler: { params in
                guard !params.isEmpty else { return nil }
                let taskTitle = params.joined(separator: " ")
                return ParsedCommand(action: "task.add", parameters: [taskTitle], fullText: "")
            }
        ),
        CommandPattern(
            keywords: ["pomodoro", "помодоро", "pomo", "таймер", "timer"],
            actions: [],
            handler: { params in
                if let firstParam = params.first,
                   let minutes = Int(firstParam),
                   minutes > 0 && minutes <= 180 {
                    return ParsedCommand(action: "pomodoro.start", parameters: ["\(minutes)"], fullText: "")
                }
                return nil
            }
        )
    ]
    
    func parse(_ input: String) -> ParsedCommand? {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespaces)
        let words = lowercased.split(separator: " ").map { String($0) }
        
        guard words.count >= 1 else { return nil }
        
        for pattern in commandPatterns {
            if let result = pattern.tryParse(words: words, fullInput: input) {
                return result
            }
        }
        
        return nil
    }
}

struct CommandPattern {
    let keywords: [String]
    let actions: [String]
    let handler: ([String]) -> ParsedCommand?
    
    func tryParse(words: [String], fullInput: String) -> ParsedCommand? {
        guard words.count >= 1 else { return nil }
        
        let firstWord = words[0]
        
        guard keywords.contains(firstWord) else { return nil }
        
        if actions.isEmpty {
            let params = Array(words.dropFirst())
            if var result = handler(params) {
                result.fullText = fullInput
                return result
            }
            return nil
        }
        
        if words.count >= 2 {
            let secondWord = words[1]
            
            if actions.contains(secondWord) {
                let params = Array(words.dropFirst(2))
                if var result = handler(params) {
                    result.fullText = fullInput
                    return result
                }
                return nil
            }
        }
        
        return nil
    }
}


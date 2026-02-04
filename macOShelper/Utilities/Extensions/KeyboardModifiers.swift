internal import AppKit

struct KeyboardModifiers {
    static let cmdKey: UInt32 = 0x0100
    static let shiftKey: UInt32 = 0x0200
    static let optionKey: UInt32 = 0x0800
    static let controlKey: UInt32 = 0x1000
    
    static func toNSEventModifiers(_ carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        
        if carbonModifiers & cmdKey != 0 { flags.insert(.command) }
        if carbonModifiers & controlKey != 0 { flags.insert(.control) }
        if carbonModifiers & optionKey != 0 { flags.insert(.option) }
        if carbonModifiers & shiftKey != 0 { flags.insert(.shift) }
        
        return flags
    }
    
    static func toCarbonModifiers(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        
        if modifiers.contains(.command) { carbon |= cmdKey }
        if modifiers.contains(.control) { carbon |= controlKey }
        if modifiers.contains(.option) { carbon |= optionKey }
        if modifiers.contains(.shift) { carbon |= shiftKey }
        
        return carbon
    }
    
    static func formatKeyCombo(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        
        parts.append(getKeyName(keyCode: keyCode))
        
        return parts.joined(separator: " ")
    }
    
    private static func getKeyName(keyCode: UInt16) -> String {
        let keyNames: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U",
            34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            49: "Space", 36: "Enter", 48: "Tab", 51: "Delete", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        
        return keyNames[keyCode] ?? "Key \(keyCode)"
    }
}


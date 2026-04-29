import SwiftUI
internal import AppKit

extension Color {
    /// Семантические цвета приложения, привязанные к системной палитре macOS
    /// (чтобы UI выглядел "по-Apple" и корректно работал в Light/Dark).
    static let blackApp = Color(nsColor: .windowBackgroundColor)
    static let grayApp = Color(nsColor: .controlBackgroundColor)
    static let lightGrayApp = Color(nsColor: .textBackgroundColor)

    static let mainTextApp = Color(nsColor: .labelColor)
    static let secondaryTextApp = Color(nsColor: .secondaryLabelColor)

    static let blueAccent = Color(nsColor: .controlAccentColor)
    static let greenAccent = Color(nsColor: .systemGreen)
    static let redAccent = Color(nsColor: .systemRed)
    static let orangeAccent = Color(nsColor: .systemOrange)
    static let yellowAccent = Color(nsColor: .systemYellow)

    static let cardBackgroundApp = Color(nsColor: .controlBackgroundColor)
    static let borderApp = Color(nsColor: .separatorColor)
}

extension Color {
    init(nsColor: NSColor) {
        self.init(nsColor)
    }

    static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: .adaptiveColor(lightHex: light, darkHex: dark))
    }

    init(hex: String, alpha: Double = 1) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        let red = (rgbValue & 0xFF0000) >> 16
        let green = (rgbValue & 0xFF00) >> 8
        let blue = rgbValue & 0xFF
        
        self.init(
            .sRGB,
            red: Double(red) / 0xFF,
            green: Double(green) / 0xFF,
            blue: Double(blue) / 0xFF,
            opacity: alpha
        )
    }
}

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (red, green, blue) = (int >> 8, (int >> 4) & 0xF, int & 0xF)
            self.init(red: CGFloat(red * 17) / 255.0, green: CGFloat(green * 17) / 255.0, blue: CGFloat(blue * 17) / 255.0, alpha: alpha)
        case 6: // RGB (24-bit)
            (red, green, blue) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
            self.init(
                red: CGFloat(red) / 255.0,
                green: CGFloat(green) / 255.0,
                blue: CGFloat(blue) / 255.0,
                alpha: alpha
            )
        default:
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
        }
    }

    static func adaptiveColor(lightHex: String, darkHex: String) -> NSColor {
        let appearance = NSApplication.shared.effectiveAppearance
        let isDark = appearance.name == .darkAqua
        
        return NSColor(hex: isDark ? darkHex : lightHex)
    }
}

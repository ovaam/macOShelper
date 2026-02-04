import SwiftUI
internal import AppKit

extension Color {
    static let blackApp = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFF5F5", darkHex: "#FFF5F5"))
    static let grayApp = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFE8E8", darkHex: "#FFE8E8"))
    static let lightGrayApp = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFDEDE", darkHex: "#FFDEDE"))
    static let mainTextApp = Color(nsColor: NSColor(hex: "#5A4A4A"))
    static let secondaryTextApp = Color(nsColor: NSColor(hex: "#8B7A7A"))
    static let blueAccent = Color(nsColor: NSColor.adaptiveColor(lightHex: "#B5E5CF", darkHex: "#B5E5CF"))
    static let greenAccent = Color(nsColor: NSColor.adaptiveColor(lightHex: "#A8D5C4", darkHex: "#A8D5C4"))
    static let redAccent = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFB3BA", darkHex: "#FFB3BA"))
    static let orangeAccent = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFD4A3", darkHex: "#FFD4A3"))
    static let yellowAccent = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFE5B4", darkHex: "#FFE5B4"))
    static let cardBackgroundApp = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFF0F0", darkHex: "#FFF0F0"))
    static let borderApp = Color(nsColor: NSColor.adaptiveColor(lightHex: "#FFD6D6", darkHex: "#FFD6D6"))
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

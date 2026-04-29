import SwiftUI

enum CustomFonts: String {
    case sansBold = "HSESans-Bold"
    case sansItalic = "HSESans-Italic"
    case sansRegular = "HSESans-Regular"
    case sansSemiBold = "HSESans-SemiBold"
    case sansThin = "HSESans-Thin"
}

private extension Font {
    static func custom(_ customFont: CustomFonts, size: CGFloat) -> Font {
        // Переиспользуем существующие вызовы `font(customFont:, size:)`,
        // но рендерим системным шрифтом, чтобы интерфейс выглядел нативно.
        switch customFont {
        case .sansBold:
            return .system(size: size, weight: .bold)
        case .sansSemiBold:
            return .system(size: size, weight: .semibold)
        case .sansRegular:
            return .system(size: size, weight: .regular)
        case .sansThin:
            return .system(size: size, weight: .thin)
        case .sansItalic:
            return .system(size: size, weight: .regular).italic()
        }
    }
}

extension Text {
    func font(customFont: CustomFonts, size: CGFloat) -> Text {
        font(Font.custom(customFont, size: size))
    }
}

extension Button {
    func font(customFont: CustomFonts, size: CGFloat) -> some View {
        font(Font.custom(customFont, size: size))
    }
}

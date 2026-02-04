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
        Font.custom(customFont.rawValue, size: size)
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

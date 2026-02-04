import SwiftUI

// MARK: – Основные стили

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("HSESans-Regular", size: 14))
            .foregroundColor(.mainTextApp)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.greenAccent.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("HSESans-SemiBold", size: 14))
            .foregroundColor(.mainTextApp)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.lightGrayApp.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: – Хелперы

extension Button {
    /// Комментарий: применяет основной стиль действия (primary)
    func applyPrimaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    /// Комментарий: применяет дополнительный стиль (secondary)
    func applySecondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

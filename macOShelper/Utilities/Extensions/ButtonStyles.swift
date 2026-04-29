import SwiftUI

// MARK: – Основные стили

/// Legacy-стили оставлены для совместимости, но переведены на системный вид.
/// Рекомендуемый путь — использовать `applyPrimaryButton()` / `applySecondaryButton()`.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.85 : 1.0))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .regular))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: – Хелперы

extension Button {
    func applyPrimaryButton() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
    }

    func applySecondaryButton() -> some View {
        self
            .buttonStyle(.bordered)
            .controlSize(.regular)
    }
}

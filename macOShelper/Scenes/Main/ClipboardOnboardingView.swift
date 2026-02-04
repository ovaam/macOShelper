import SwiftUI

struct ClipboardOnboardingView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(Color.grayApp.opacity(0.5))
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    sectionTitle("Основные действия")
                    onboardingItem(icon: "cursorarrow.rays", title: "Вставка по клику", description: "Нажмите на любую запись, чтобы сразу вставить её содержимое в активное поле.")
                    onboardingItem(icon: "command.square", title: "Горячие клавиши", description: "Назначайте свои сочетания для любых записей через иконку клавиатуры. После назначения комбинация работает в любом приложении.")
                    onboardingItem(icon: "trash", title: "Удаление записи", description: "Иконка корзины рядом с записью удаляет её из истории. Кнопка «Очистить» в правом верхнем углу очищает весь список.")

                    sectionTitle("Работа с изображениями")
                    onboardingItem(icon: "photo", title: "Миниатюры", description: "Картинки отображаются с превью. Удерживайте запись примерно 0.7 секунды, чтобы открыть изображение на весь экран.")

                    sectionTitle("Другие типы данных")
                    onboardingItem(icon: "doc", title: "Файлы и ссылки", description: "MacDuck сохраняет файлы, форматированный текст и HTML. Подписи показывают тип содержимого и названия файлов.")

                    sectionTitle("Глобальные сочетания")
                    onboardingItem(icon: "keyboard", title: "Использование hotkey", description: "Назначенные сочетания работают в любой программе: MacDuck подменяет содержимое буфера и имитирует ⌘V.")
                }
                .padding(24)
            }
        }
        .frame(width: 480, height: 540)
        .background(Color.blackApp)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Как пользоваться буфером MacDuck")
                    .font(Font.custom("HSESans-Bold", size: 20))
                    .foregroundColor(.mainTextApp)
                Text("Краткий гайд по действиям внутри вкладки «Буфер обмена».")
                    .font(Font.custom("HSESans-Regular", size: 13))
                    .foregroundColor(.secondaryTextApp)
            }
            Spacer()
            Button("Закрыть") {
                dismiss()
            }
            .applySecondaryButton()
            .focusable(false)
        }
        .padding(20)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("HSESans-SemiBold", size: 15))
            .foregroundColor(.secondaryTextApp)
            .padding(.top, 8)
    }

    private func onboardingItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondaryTextApp)
                .frame(width: 32, height: 32)
                .background(Color.grayApp.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.mainTextApp)
                Text(description)
                    .font(Font.custom("HSESans-Regular", size: 13))
                    .foregroundColor(.secondaryTextApp)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ClipboardOnboardingView()
}

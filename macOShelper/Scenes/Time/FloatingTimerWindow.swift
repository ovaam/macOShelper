import SwiftUI

struct FloatingTimerWindow: View {
    @ObservedObject var service = PomodoroService.shared

    @State private var isHovered: Bool = false

    private let collapsedSize = CGSize(width: 180, height: 96)
    private let expandedSize  = CGSize(width: 260, height: 160)

    var body: some View {
        ZStack {
            Color.blackApp.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Фокус")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)

                Text(timeString(service.state?.remaining ?? 0))
                    .font(Font.custom("HSESans-Bold", size: 34))
                    .foregroundColor(.mainTextApp)
                    .padding(.top, 2)

                if isHovered {
                    HStack(spacing: 8) {
                        if service.isRunning() {
                            Button("Пауза") {
                                service.togglePause()
                            }
                            .applySecondaryButton()
                        } else if service.isPaused() {
                            Button("Продолжить") {
                                service.togglePause()
                            }
                            .applySecondaryButton()
                        }

                        Button("Стоп") {
                            service.stop(save: true)
                            FloatingWindowManager.shared.close()
                        }
                        .applyPrimaryButton()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .frame(
            width: isHovered ? expandedSize.width : collapsedSize.width,
            height: isHovered ? expandedSize.height : collapsedSize.height
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: isHovered ? 10 : 4)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isHovered)
    }

    // MARK: - Helpers

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

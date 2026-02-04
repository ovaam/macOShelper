import SwiftUI

struct ProductivityChart: View {
    let data: [TimeInterval]
    
    private var maxValue: TimeInterval {
        data.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                VStack {
                    // Подпись с количеством минут над столбиком
                    Text(formatTime(value))
                        .font(.caption2)
                        .foregroundColor(.secondaryTextApp)
                        .padding(.bottom, 4)

                    // Столбик
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.grayApp)
                        .frame(height: CGFloat(value / maxValue) * 100)

                    // Подпись дня недели
                    Text(shortDay(for: i))
                        .font(.caption2)
                        .foregroundColor(.secondaryTextApp)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut, value: data)
    }
    
    private func shortDay(for index: Int) -> String {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: day).capitalized
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h) ч \(m) мин" : "\(h) ч"
        } else {
            return "\(minutes) мин"
        }
    }
}

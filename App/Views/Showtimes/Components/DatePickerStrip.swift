import SwiftUI

// MARK: - DatePickerStrip

/// Horizontal date picker strip hiển thị 7 ngày tới
/// Format: Thứ / Ngày / Tháng theo Tiếng Việt
struct DatePickerStrip: View {
    let dates: [Date]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dates, id: \.self) { date in
                    DateCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        onDateSelected(date)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Date Cell

private struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }

    private var dayNumber: String {
        calendar.component(.day, from: date).description
    }

    private var monthNumber: String {
        "Th.\(calendar.component(.month, from: date))"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(isToday ? "Hôm nay" : dayOfWeek)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .black : .gray)

                Text(dayNumber)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(isSelected ? .black : .white)

                Text(monthNumber)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .gray)
            }
            .frame(width: 58, height: 76)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(hex: "#D4AF37"), Color(hex: "#F0C850")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.white.opacity(isToday ? 0.12 : 0.06)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.clear : (isToday ? Color(hex: "#D4AF37").opacity(0.4) : Color.white.opacity(0.1)),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

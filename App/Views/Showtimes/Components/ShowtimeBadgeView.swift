import SwiftUI

// MARK: - ShowtimeBadgeView

/// Badge hiển thị một suất chiếu với trạng thái còn ghế/sắp hết/hết vé
struct ShowtimeBadgeView: View {
    let showtime: Showtime

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: showtime.startTime)
    }

    private var availability: Showtime.Availability {
        showtime.availability
    }

    private var availabilityColor: Color {
        switch availability {
        case .available:  return Color(hex: "#22C55E")   // xanh lá
        case .almostFull: return Color(hex: "#F59E0B")   // vàng cam
        case .soldOut:    return Color(hex: "#6B7280")   // xám
        }
    }

    private var isDisabled: Bool {
        availability == .soldOut
    }

    var body: some View {
        VStack(spacing: 5) {
            // Time
            Text(timeString)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(isDisabled ? .gray : .white)

            // Availability label
            Text(availability.label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isDisabled ? .gray : availabilityColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDisabled
                      ? Color.white.opacity(0.04)
                      : availabilityColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isDisabled ? Color.gray.opacity(0.2) : availabilityColor.opacity(0.4),
                            lineWidth: 1.5
                        )
                )
        )
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled)
    }
}

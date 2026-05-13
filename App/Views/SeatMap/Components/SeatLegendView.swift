import SwiftUI

// MARK: - SeatLegendView

/// Hiển thị chú thích các loại ghế và trạng thái
/// v2: Cải thiện visual, icon đặc trưng cho từng loại
struct SeatLegendView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                LegendItem(color: Color(hex: "#5B8DEF"),  icon: nil,  label: "Thường")
                LegendItem(color: Color(hex: "#FF9F43"),  icon: "★",  label: "VIP")
                LegendItem(color: Color(hex: "#C2185B"),  icon: "♥",  label: "Sweetbox")
                LegendItem(color: Color(hex: "#39D98A"),  icon: nil,  label: "Đang chọn")
                LegendItem(color: Color(hex: "#2A2A3A"),  icon: nil,  label: "Đã mua", textColor: Color(hex: "#555566"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            Color(hex: "#0F0F1A").opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - LegendItem

private struct LegendItem: View {
    let color: Color
    let icon: String?
    let label: String
    var textColor: Color = .white

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 22, height: 10)
                            .offset(y: -6),
                        alignment: .center
                    )

                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }
}
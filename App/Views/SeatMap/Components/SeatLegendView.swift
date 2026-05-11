import SwiftUI

// MARK: - SeatLegendView

/// Hiển thị chú thích các loại ghế và trạng thái
struct SeatLegendView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                LegendItem(color: Color(hex: "#E0E0E0"), label: "Thường")
                LegendItem(color: Color(hex: "#F0C850"), label: "VIP")
                LegendItem(color: Color(hex: "#FF66CC"), label: "Couple")
                LegendItem(color: Color(hex: "#D4AF37"), label: "Đang chọn")
                LegendItem(color: Color(hex: "#333333"), label: "Đã bán")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "#1C1C1E").opacity(0.8))
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

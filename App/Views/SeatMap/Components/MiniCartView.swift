import SwiftUI

// MARK: - MiniCartView

/// Float ở dưới cùng, hiển thị danh sách ghế đang chọn và tổng tiền
struct MiniCartView: View {
    let selectedSeats: [Seat]
    let totalPrice: String
    let onContinue: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if selectedSeats.isEmpty {
                    Text("Vui lòng chọn ghế")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                } else {
                    let seatNames = selectedSeats.map(\.displayName).joined(separator: ", ")
                    Text("Ghế: \(seatNames)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Tạm tính: \(totalPrice)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#00D2D3"))
                }
            }
            
            Spacer()
            
            Button(action: onContinue) {
                HStack {
                    Text("Tiếp tục")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(selectedSeats.isEmpty ? Color.gray : Color(hex: "#00D2D3"))
                .cornerRadius(12)
            }
            .disabled(selectedSeats.isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1C1C1E").opacity(0.9))
                // Glassmorphism effect iOS 15 compatible
                .background(BlurView(style: .systemThinMaterialDark).clipShape(RoundedRectangle(cornerRadius: 16)))
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - BlurView

/// UIViewRepresentable cho UIBlurEffect để hỗ trợ tốt trên iOS 15
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

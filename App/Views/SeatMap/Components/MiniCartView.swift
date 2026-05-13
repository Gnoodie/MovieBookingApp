import SwiftUI

// MARK: - MiniCartView

/// Float ở dưới cùng, hiển thị danh sách ghế đang chọn và tổng tiền
/// v2: Animation mượt hơn, visual cải thiện
struct MiniCartView: View {
    let selectedSeats: [Seat]
    let totalPrice: String
    let onContinue: () -> Void

    private var hasSeats: Bool { !selectedSeats.isEmpty }

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Seat Info
            VStack(alignment: .leading, spacing: 3) {
                if hasSeats {
                    HStack(spacing: 6) {
                        // Badge số lượng ghế
                        Text("\(selectedSeats.count)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                            .background(Color(hex: "#39D98A"))
                            .clipShape(Circle())

                        let seatNames = selectedSeats.map(\.displayName).joined(separator: ", ")
                        Text(seatNames)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))

                    Text(totalPrice)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#39D98A"))
                        .transition(.opacity)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#555566"))
                        Text("Chọn ghế để tiếp tục")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#555566"))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: hasSeats)

            Spacer()

            // MARK: Continue Button
            Button(action: onContinue) {
                HStack(spacing: 6) {
                    Text("Tiếp tục")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(hasSeats ? .black : Color(hex: "#333344"))
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(
                    hasSeats
                    ? Color(hex: "#39D98A")
                    : Color(hex: "#1E1E2E")
                )
                .clipShape(Capsule())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasSeats)
            }
            .disabled(!hasSeats)
            .scaleEffect(hasSeats ? 1.0 : 0.96)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasSeats)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterialDark)
                Color(hex: "#0D0D1A").opacity(0.7)
                // Top border line
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: -8)
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
}

// MARK: - BlurView

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
import SwiftUI

// MARK: - FloatingHoldTimerBar

/// Thanh hiển thị thời gian giữ ghế nổi ở phía trên màn hình
/// v2: Animation pulse khi warning, visual sạch hơn
struct FloatingHoldTimerBar: View {
    let timeFormatted: String
    let isWarning: Bool

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            // Icon đồng hồ
            ZStack {
                Circle()
                    .fill(isWarning ? Color.red.opacity(0.2) : Color(hex: "#39D98A").opacity(0.15))
                    .frame(width: 28, height: 28)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 1)

                Image(systemName: isWarning ? "exclamationmark.circle.fill" : "clock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isWarning ? .red : Color(hex: "#39D98A"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(isWarning ? "Sắp hết giờ!" : "Thời gian giữ ghế")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isWarning ? Color.red.opacity(0.8) : Color(hex: "#888888"))

                Text(timeFormatted)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(isWarning ? .red : .white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            ZStack {
                BlurView(style: .systemThinMaterialDark)
                Color(isWarning ? "#1A0505" : "#0A1A0F").opacity(0.6)
            }
            .clipShape(Capsule())
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    isWarning
                    ? Color.red.opacity(0.7)
                    : Color(hex: "#39D98A").opacity(0.4),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isWarning ? Color.red.opacity(0.3) : Color(hex: "#39D98A").opacity(0.2),
            radius: 12, x: 0, y: 4
        )
        .onChange(of: isWarning) { warning in
            if warning {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}
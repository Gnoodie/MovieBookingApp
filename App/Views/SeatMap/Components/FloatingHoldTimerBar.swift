import SwiftUI

// MARK: - FloatingHoldTimerBar

/// Thanh hiển thị thời gian giữ ghế nổi ở phía trên màn hình
struct FloatingHoldTimerBar: View {
    let timeFormatted: String
    let isWarning: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(isWarning ? .red : .white)
                .font(.system(size: 14, weight: .bold))
                
            Text("Thời gian giữ ghế: \(timeFormatted)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isWarning ? .red : .white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(hex: "#1C1C1E").opacity(0.9))
                .shadow(color: isWarning ? Color.red.opacity(0.3) : .black.opacity(0.3), radius: 10, y: 5)
        )
        .overlay(
            Capsule()
                .strokeBorder(isWarning ? Color.red.opacity(0.8) : Color(hex: "#D4AF37").opacity(0.5), lineWidth: 1)
        )
        // Animation nhấp nháy khi warning
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWarning)
    }
}

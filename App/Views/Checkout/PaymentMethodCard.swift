import SwiftUI

// MARK: - PaymentMethodCard

/// Card chọn phương thức thanh toán — radio style
/// Dùng trong CheckoutView, mỗi PaymentMethod 1 card
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            guard method.isAvailable else { return }
            HapticManager.shared.selection()
            onTap()
        } label: {
            HStack(spacing: 14) {
                // Icon
                Text(method.icon)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Name + Description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(method.displayName)
                            .font(.headingSmall)
                            .foregroundColor(method.isAvailable ? .textPrimary : .textDisabled)

                        // Badge "Sắp có" cho Apple Pay
                        if !method.isAvailable {
                            Text("Sắp có")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.textDisabled)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(4)
                        }
                    }

                    Text(methodDescription)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Radio indicator
                radioIndicator
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentTeal : Color.backgroundTertiary,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(method.isAvailable ? 1 : 0.5)
            .animation(.cinematicSpring, value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!method.isAvailable)
    }

    // MARK: - Radio Indicator

    private var radioIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Color.accentTeal : Color.backgroundTertiary,
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(Color.accentTeal)
                    .frame(width: 12, height: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.cinematicSpring, value: isSelected)
    }

    // MARK: - Description Text

    private var methodDescription: String {
        switch method {
        case .momo:     return "Thanh toán qua ví MoMo"
        case .vnpay:    return "Thanh toán qua VNPay"
        case .applePay: return "Thanh toán bằng Apple Pay"
        case .mockPay:  return "Giả lập thanh toán (Dev)"
        }
    }
}

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
                    .background(iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Name + Description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(method.displayName)
                            .font(.headingSmall)
                            .foregroundColor(method.isAvailable ? .textPrimary : .textDisabled)

                        // Badge: "Khuyên dùng" cho QR Demo, "Sắp có" cho Apple Pay
                        if method == .mockPay {
                            Text("Khuyên dùng")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#D4AF37"))
                                .cornerRadius(4)
                        } else if !method.isAvailable {
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
                    .fill(method == .mockPay && isSelected
                          ? Color(hex: "#D4AF37").opacity(0.08)
                          : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? (method == .mockPay ? Color(hex: "#D4AF37") : Color.accentTeal)
                            : Color.backgroundTertiary,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(method.isAvailable ? 1 : 0.5)
            .animation(.cinematicSpring, value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!method.isAvailable)
    }

    // MARK: - Icon Background

    private var iconBackground: Color {
        switch method {
        case .mockPay:  return Color(hex: "#D4AF37").opacity(0.15)
        default:        return Color.white.opacity(0.08)
        }
    }

    // MARK: - Radio Indicator

    private var radioIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected
                        ? (method == .mockPay ? Color(hex: "#D4AF37") : Color.accentTeal)
                        : Color.backgroundTertiary,
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(method == .mockPay ? Color(hex: "#D4AF37") : Color.accentTeal)
                    .frame(width: 12, height: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.cinematicSpring, value: isSelected)
    }

    // MARK: - Description Text

    private var methodDescription: String {
        switch method {
        case .mockPay:  return "Quét mã QR demo — hoàn tất đặt vé ngay lập tức"
        case .momo:     return "Thanh toán qua ví MoMo (Đang thử nghiệm)"
        case .vnpay:    return "Thanh toán qua VNPay (Đang thử nghiệm)"
        case .applePay: return "Thanh toán bằng Apple Pay (Sắp ra mắt)"
        }
    }
}

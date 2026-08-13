import SwiftUI

// MARK: - QRDemoPaymentSheet

/// Sheet thanh toán QR Demo — hiện khi người dùng chọn "Thanh toán QR Demo"
/// Mô phỏng flow quét mã QR để Apple reviewer có thể hoàn tất luồng đặt vé
struct QRDemoPaymentSheet: View {
    let totalFormatted: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var isPulsingQR = false
    @State private var isProcessing = false
    @State private var progressValue: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#06060C").ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                // Header
                VStack(spacing: 6) {
                    Text("⚡ Thanh toán QR Demo")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Quét mã để xác nhận thanh toán")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(hex: "#888888"))
                }

                Spacer().frame(height: 32)

                // QR Code Frame
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#D4AF37").opacity(isPulsingQR ? 0.15 : 0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(isPulsingQR ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isPulsingQR
                        )

                    // QR Card background
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 200, height: 200)

                    // QR Pattern (simulated)
                    QRPatternView()
                        .frame(width: 180, height: 180)

                    // Demo overlay badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("DEMO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#D4AF37"))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .frame(width: 200, height: 200)
                    .padding(8)
                }

                Spacer().frame(height: 28)

                // Amount
                VStack(spacing: 4) {
                    Text("Số tiền cần thanh toán")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color(hex: "#888888"))
                    Text(totalFormatted)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#D4AF37"))
                }

                Spacer().frame(height: 8)

                // Info note
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#39D98A"))
                    Text("Đây là môi trường demo — không cần thanh toán thật")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.horizontal, 24)
                .multilineTextAlignment(.center)

                Spacer()

                // Progress bar (simulated "đang quét")
                if isProcessing {
                    VStack(spacing: 8) {
                        Text("Đang xử lý...")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "#888888"))
                        ProgressView(value: progressValue)
                            .tint(Color(hex: "#39D98A"))
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                    Spacer().frame(height: 16)
                }

                // Buttons
                VStack(spacing: 12) {
                    // Confirm button
                    Button {
                        guard !isProcessing else { return }
                        HapticManager.shared.notification(type: .success)
                        isProcessing = true

                        // Animate progress then confirm
                        withAnimation(.linear(duration: 1.2)) {
                            progressValue = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            onConfirm()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                            }
                            Text(isProcessing ? "Đang xử lý..." : "Xác nhận thanh toán")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            isProcessing
                                ? Color(hex: "#D4AF37").opacity(0.7)
                                : Color(hex: "#D4AF37")
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isProcessing)

                    // Cancel button
                    Button {
                        guard !isProcessing else { return }
                        onCancel()
                    } label: {
                        Text("Huỷ")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#888888"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { isPulsingQR = true }
    }
}

// MARK: - QRPatternView

/// View mô phỏng mã QR bằng grid ô vuông
private struct QRPatternView: View {
    // Pattern 9×9 cứng (chỉ để demo visual)
    private let pattern: [[Bool]] = [
        [true,  true,  true,  true,  true,  true,  true,  false, true ],
        [true,  false, false, false, false, false, true,  false, false],
        [true,  false, true,  true,  true,  false, true,  false, true ],
        [true,  false, true,  true,  true,  false, true,  false, true ],
        [true,  false, true,  true,  true,  false, true,  false, false],
        [true,  false, false, false, false, false, true,  false, true ],
        [true,  true,  true,  true,  true,  true,  true,  false, true ],
        [false, false, false, false, false, false, false, false, false],
        [true,  false, true,  false, true,  false, false, false, true ],
    ]

    var body: some View {
        GeometryReader { geo in
            let cols = pattern[0].count
            let rows = pattern.count
            let cellW = geo.size.width / CGFloat(cols)
            let cellH = geo.size.height / CGFloat(rows)

            Canvas { context, _ in
                for r in 0..<rows {
                    for c in 0..<cols {
                        if pattern[r][c] {
                            let rect = CGRect(
                                x: CGFloat(c) * cellW + 1,
                                y: CGFloat(r) * cellH + 1,
                                width: cellW - 2,
                                height: cellH - 2
                            )
                            context.fill(Path(rect), with: .color(.black))
                        }
                    }
                }
            }
        }
    }
}

import SwiftUI
import CoreImage.CIFilterBuiltins

@available(iOS 18.0, *)
struct PaymentQRSnippetView: View {
    var movie: MovieEntity
    var cinema: CinemaEntity
    var showtime: ShowtimeEntity
    var seatLabels: [String]
    var totalAmount: Int
    var qrData: String
    
    @State private var secondsLeft = 30
    private let totalSeconds: CGFloat = 30.0
    @State private var isPaid = false
    @State private var timer: Timer? = nil
    
    private var qrImage: UIImage {
        generateQR(from: qrData) ?? UIImage(systemName: "qrcode") ?? UIImage()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────
            VStack(spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Label(cinema.name, systemImage: "mappin.circle.fill")
                    Label(showtime.timeString, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if !seatLabels.isEmpty {
                    Text("Ghế: \(seatLabels.joined(separator: " · "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider().padding(.vertical, 8)
            
            // ── QR Code hoặc Success ──────────────────
            if isPaid {
                // Màn hình thành công sau 30 giây
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                        .transition(.scale)
                    Text("Thanh toán thành công!")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Vé đã được lưu trong mục Vé của tôi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // NOTE: Siri & Apple Intelligence lồng ghép khéo léo
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                                .font(.system(size: 12))
                            Text("NOTE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                        }
                        Text("Đặt vé dễ dàng qua siri và apple intelligent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                }
                .padding()
                .animation(.spring(), value: isPaid)
            } else {
                VStack(spacing: 8) {
                    // QR Code
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    // Đếm ngược
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                        Text("Mã hết hạn sau \(secondsLeft)s")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    // Thanh progress đếm ngược
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: geo.size.width * (CGFloat(secondsLeft) / totalSeconds), height: 4)
                                .animation(.linear(duration: 1), value: secondsLeft)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                }
                .padding(.horizontal)
            }
            
            Divider().padding(.vertical, 8)
            
            // ── Tổng tiền ────────────────────────────
            HStack {
                Text("Tổng cộng")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatVND(totalAmount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }
    
    // MARK: - Timer
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                t.invalidate()
                withAnimation { isPaid = true }
            }
        }
    }
    
    // MARK: - QR Generator
    private func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Helpers
    private func formatVND(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "\(f.string(from: NSNumber(value: amount)) ?? "\(amount)")đ"
    }
}

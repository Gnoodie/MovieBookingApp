import AppIntents
import SwiftUI
import FirebaseFirestore
import SharedKit

@available(iOS 18.0, *)
struct BookMovieIntent: AppIntent {
    static let title: LocalizedStringResource = "Đặt vé phim"
    static let description = IntentDescription("Đặt vé một bộ phim bất kỳ qua Siri")
    static var openAppWhenRun: Bool = false
    
    // MARK: - Parameters (Siri hỏi lần lượt từng câu)
    @Parameter(title: "Phim", requestValueDialog: "Bạn muốn xem phim gì?")
    var movie: MovieEntity
    
    @Parameter(title: "Rạp chiếu", requestValueDialog: "Bạn muốn xem ở rạp nào?")
    var cinema: CinemaEntity
    
    @Parameter(title: "Suất chiếu", requestValueDialog: "Bạn chọn suất chiếu nào?")
    var showtime: ShowtimeEntity
    
    // Không đặt default để Siri bắt buộc hỏi người dùng
    @Parameter(title: "Số lượng vé", inclusiveRange: (1, 8), requestValueDialog: "Bạn muốn đặt bao nhiêu vé? (1 đến 8)")
    var ticketCount: Int
    
    @Parameter(title: "Loại ghế", requestValueDialog: "Bạn muốn ngồi ghế loại nào? Thường, VIP, hay Ghế đôi?")
    var seatType: SeatTypeEntity
    
    // Dùng enum thay vì Bool để Siri hiển thị menu lựa chọn đẹp hơn
    @Parameter(title: "Combo đồ ăn", requestValueDialog: "Bạn có muốn thêm combo đồ ăn không?")
    var fnbOption: FnBOptionEntity
    
    // MARK: - Perform
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        FirebaseIntentSetup.configureIfNeeded()
        
        // 1. Chọn ghế ngẫu nhiên theo loại & số lượng từ Firestore
        let selectedSeats = await pickRandomSeats(
            showtimeId: showtime.id,
            seatType: seatType.rawValue,
            count: ticketCount
        )
        
        // 2. Tính tiền
        let pricePerSeat: Int
        switch seatType {
        case .vip:     pricePerSeat = 195000
        case .couple:  pricePerSeat = 250000
        default:       pricePerSeat = 150000
        }
        let totalAmount = pricePerSeat * ticketCount + fnbOption.amount
        
        // 3. Tạo QR code ảo
        let qrData = "MBK|\(showtime.id)|\(selectedSeats.joined(separator: ","))|\(Int.random(in: 1000000...9999999))"
        
        // 4. Tạo ticket document trên Firestore (trạng thái paid ngay)
        let ticketId = "siri-ticket-\(UUID().uuidString.prefix(8))"
        await createFirestoreTicket(
            ticketId: ticketId,
            showtimeId: showtime.id,
            movieTitle: movie.title,
            cinemaName: cinema.name,
            seatLabels: selectedSeats,
            totalAmount: totalAmount,
            qrData: qrData
        )
        
        let seatNames = selectedSeats.isEmpty ? "ghế ngẫu nhiên" : selectedSeats.joined(separator: ", ")
        let dialog = IntentDialog("Đã đặt \(ticketCount) vé phim \(movie.title) tại \(cinema.name), ghế \(seatNames). Tổng cộng \(formatVND(totalAmount)). Quét mã QR để thanh toán.")
        
        return .result(
            dialog: dialog,
            view: PaymentQRSnippetView(
                movie: movie,
                cinema: cinema,
                showtime: showtime,
                seatLabels: selectedSeats,
                totalAmount: totalAmount,
                qrData: qrData
            )
        )
    }
    
    // MARK: - Private Helpers
    
    private func pickRandomSeats(showtimeId: String, seatType: String, count: Int) async -> [String] {
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("showtimes")
            .document(showtimeId)
            .collection("seats")
            .whereField("type", isEqualTo: seatType)
            .whereField("status", isEqualTo: "available")
            .limit(to: count * 3) // lấy thêm dư để random
            .getDocuments()
        else { return [] }
        
        let allLabels = snapshot.documents.compactMap { $0.data()["label"] as? String }
        let shuffled = allLabels.shuffled()
        return Array(shuffled.prefix(count))
    }
    
    private func createFirestoreTicket(
        ticketId: String,
        showtimeId: String,
        movieTitle: String,
        cinemaName: String,
        seatLabels: [String],
        totalAmount: Int,
        qrData: String
    ) async {
        let db = Firestore.firestore()
        let now = Timestamp(date: Date())
        
        // Lấy userId từ SharedUserSession (được ghi khi user đăng nhập từ Main App)
        // Nếu không tìm thấy (chưa từng mở app) thì dùng fallback "siri-guest"
        let userId = SharedUserSession.getUserUid() ?? "siri-guest"
        print("📋 [BookMovieIntent] Using userId: \(userId)")
        
        let ticketData: [String: Any] = [
            "bookingId": "SIRI-\(ticketId.uppercased())",
            "orderId": ticketId,
            "userId": userId,
            "movieTitle": movieTitle,
            "cinemaName": cinemaName,
            "hallName": "Phòng chiếu",
            "showtime": now,
            "format": showtime.format,
            "seats": seatLabels.map { ["label": $0] },
            "totalAmount": totalAmount,
            "status": "active",
            "purchasedAt": now,
            "qrCodeData": qrData,
            "createdViaSiri": true
        ]
        
        do {
            try await db.collection("tickets").document(ticketId).setData(ticketData)
            print("✅ Ticket saved to Firestore successfully: \(ticketId)")
        } catch {
            print("❌ Failed to save ticket to Firestore: \(error.localizedDescription)")
        }
    }
    
    
    private func formatVND(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")đ"
    }
}

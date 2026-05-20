import AppIntents
import SwiftUI
import FirebaseFirestore

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
    
    @Parameter(title: "Số lượng vé", requestValueDialog: "Bạn muốn đặt bao nhiêu vé?", default: 1, inclusiveRange: (1, 8))
    var ticketCount: Int
    
    @Parameter(title: "Loại ghế", requestValueDialog: "Bạn muốn ngồi ghế loại nào? Thường, VIP, hay Ghế đôi?")
    var seatType: SeatTypeEntity
    
    @Parameter(title: "Dịch vụ F&B", requestValueDialog: "Bạn có muốn thêm đồ ăn uống không? Không cần, Combo Couple, hay Combo Gia đình?", default: false)
    var wantsFnB: Bool
    
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
        let fnbAmount = wantsFnB ? 150000 : 0
        let totalAmount = pricePerSeat * ticketCount + fnbAmount
        
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
        
        // Cố gắng lấy userId từ FirebaseAuth (nếu đã đăng nhập), fallback về "siri-guest"
        var userId = "siri-guest"
        if let currentUser = try? await fetchCurrentUserId() {
            userId = currentUser
        }
        
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
        
        try? await db.collection("tickets").document(ticketId).setData(ticketData)
    }
    
    private func fetchCurrentUserId() async throws -> String? {
        // Vì AppIntentsExtension chạy độc lập, không có Firebase Auth context đầy đủ
        // Trả về nil để dùng fallback "siri-guest" – user vẫn thấy vé trong app sau khi đăng nhập
        return nil
    }
    
    private func formatVND(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")đ"
    }
}

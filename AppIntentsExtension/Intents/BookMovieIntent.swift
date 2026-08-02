import AppIntents
import SwiftUI
import FirebaseFirestore

// MARK: - SelectedSeat
struct SelectedSeat {
    let label: String
    let row: String
    let number: Int
    let type: String
    let price: Double
}

@available(iOS 18.0, *)
struct BookMovieIntent: AppIntent {
    static let title: LocalizedStringResource = "Đặt vé phim"
    static let description = IntentDescription("Đặt vé một bộ phim bất kỳ")
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
        
        // MARK: Bước 1 — Kiểm tra số ghế khả dụng trước khi đặt
        let availableCount = await countAvailableSeats(
            showtimeId: showtime.id,
            seatType: seatType.rawValue
        )
        
        if availableCount == 0 {
            // Hết ghế loại này → bắt buộc chọn suất chiếu khác
            showtime = try await $showtime.requestValue(
                "Rất tiếc, suất chiếu \(showtime.timeString) đã hết ghế \(seatType.displayName). Bạn muốn chọn suất chiếu nào khác?"
            )
        } else if availableCount < ticketCount {
            // Không đủ số ghế → hỏi người dùng muốn giảm số vé hay đổi suất chiếu
            do {
                // Hỏi xác nhận: Yes → giảm số vé, No (catch) → hỏi suất khác
                try await requestConfirmation(
                    result: .result(
                        dialog: IntentDialog(
                            "Suất chiếu \(showtime.timeString) chỉ còn \(availableCount) ghế \(seatType.displayName), không đủ \(ticketCount) vé bạn yêu cầu. Bạn có muốn đặt \(availableCount) vé không?"
                        )
                    )
                )
                // Người dùng đồng ý → giảm số vé xuống mức tối đa còn lại
                ticketCount = availableCount
            } catch {
                // Người dùng không muốn giảm → đề nghị chọn suất chiếu khác
                showtime = try await $showtime.requestValue(
                    "Bạn muốn chọn suất chiếu nào khác?"
                )
            }
        }
        // Nếu availableCount >= ticketCount: đủ ghế, tiếp tục bình thường
        
        // MARK: Bước 2 — Chọn ghế ngẫu nhiên theo loại & số lượng
        let selectedSeats = await pickRandomSeats(
            showtimeId: showtime.id,
            seatType: seatType.rawValue,
            count: ticketCount
        )
        
        // Safety net: kiểm tra lần cuối sau khi đã hỏi lại người dùng
        guard !selectedSeats.isEmpty else {
            throw BookMovieError.insufficientSeats(requested: ticketCount, available: 0)
        }
        
        // MARK: Bước 3 — Tính tiền từ giá thực tế của ghế lấy từ database
        let seatPriceTotal = selectedSeats.reduce(0) { $0 + Int($1.price) }
        let totalAmount = seatPriceTotal + fnbOption.amount
        
        // MARK: Bước 4 — Tạo QR code
        let seatLabels = selectedSeats.map { $0.label }
        let qrData = "MBK|\(showtime.id)|\(seatLabels.joined(separator: ","))|\(Int.random(in: 1_000_000...9_999_999))"
        
        // MARK: Bước 5 — Lưu ticket lên Firestore & Cập nhật trạng thái ghế
        let ticketId = "siri-ticket-\(UUID().uuidString.prefix(8))"
        await createFirestoreTicket(
            ticketId: ticketId,
            showtimeId: showtime.id,
            movieId: movie.id,
            movieTitle: movie.title,
            cinema: cinema,
            seats: selectedSeats,
            totalAmount: totalAmount,
            qrData: qrData
        )
        
        let seatNames = seatLabels.joined(separator: ", ")
        let dialog = IntentDialog(
            "Đã đặt \(ticketCount) vé phim \(movie.title) tại \(cinema.name), ghế \(seatNames). Tổng cộng \(formatVND(totalAmount)). Quét mã QR để thanh toán."
        )
        
        return .result(
            dialog: dialog,
            view: PaymentQRSnippetView(
                movie: movie,
                cinema: cinema,
                showtime: showtime,
                seatLabels: seatLabels,
                totalAmount: totalAmount,
                qrData: qrData
            )
        )
    }
    
    // MARK: - Private Helpers
    
    /// Đếm tổng số ghế còn trống theo loại, dùng để kiểm tra trước khi đặt
    private func countAvailableSeats(showtimeId: String, seatType: String) async -> Int {
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("showtimes")
            .document(showtimeId)
            .collection("seats")
            .whereField("type", isEqualTo: seatType)
            .whereField("status", isEqualTo: "available")
            .getDocuments()
        else { return 0 }
        return snapshot.documents.count
    }
    
    /// Chọn ngẫu nhiên `count` ghế từ danh sách ghế trống và lấy thông tin chi tiết ghế
    private func pickRandomSeats(showtimeId: String, seatType: String, count: Int) async -> [SelectedSeat] {
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("showtimes")
            .document(showtimeId)
            .collection("seats")
            .whereField("type", isEqualTo: seatType)
            .whereField("status", isEqualTo: "available")
            .limit(to: count * 3) // lấy dư để random tự nhiên hơn
            .getDocuments()
        else { return [] }
        
        let selectedDocs = snapshot.documents.shuffled().prefix(count)
        return selectedDocs.compactMap { doc in
            let data = doc.data()
            guard let label = data["label"] as? String,
                  let row = data["row"] as? String,
                  let number = data["number"] as? Int,
                  let type = data["type"] as? String else { return nil }
            
            let price: Double
            if let priceDouble = data["price"] as? Double {
                price = priceDouble
            } else if let priceInt = data["price"] as? Int {
                price = Double(priceInt)
            } else {
                return nil
            }
            
            return SelectedSeat(label: label, row: row, number: number, type: type, price: price)
        }
    }
    
    private func createFirestoreTicket(
        ticketId: String,
        showtimeId: String,
        movieId: String,
        movieTitle: String,
        cinema: CinemaEntity,
        seats: [SelectedSeat],
        totalAmount: Int,
        qrData: String
    ) async {
        let db = Firestore.firestore()
        let now = Timestamp(date: Date())
        
        // 1. Lấy startTime thực tế của showtime từ Firestore để làm ngày/giờ chiếu chính xác
        var showtimeTimestamp = now
        if let showtimeDoc = try? await db.collection("showtimes").document(showtimeId).getDocument(),
           let showtimeData = showtimeDoc.data(),
           let startTime = showtimeData["startTime"] as? Timestamp {
            showtimeTimestamp = startTime
        }
        
        // 2. Lấy posterURL của phim từ Firestore
        var posterURL: String? = nil
        if let movieDoc = try? await db.collection("movies").document(movieId).getDocument(),
           let movieData = movieDoc.data() {
            posterURL = movieData["posterURL"] as? String
        }
        
        // 3. Lấy userId từ SharedUserSession (được ghi khi user đăng nhập từ Main App)
        // Nếu không tìm thấy (chưa từng mở app) thì dùng fallback "siri-guest"
        let userId = SharedUserSession.getUserUid() ?? "siri-guest"
        print("📋 [BookMovieIntent] Using userId: \(userId)")
        
        // 4. Map thông tin ghế đúng format mà app chính mong đợi [row, number, type, price]
        let seatsData = seats.map { seat in
            return [
                "row": seat.row,
                "number": seat.number,
                "type": seat.type,
                "price": seat.price
            ] as [String: Any]
        }
        
        let ticketData: [String: Any] = [
            "bookingId": "SIRI-\(ticketId.uppercased())",
            "orderId": ticketId,
            "userId": userId,
            "movieTitle": movieTitle,
            "moviePosterURL": posterURL as Any,
            "cinemaName": cinema.name,
            "cinemaAddress": cinema.location, // Địa chỉ rạp lấy từ cinema.location
            "hallName": "Phòng chiếu",
            "showtime": showtimeTimestamp, // Ngày giờ chiếu chuẩn
            "format": showtime.format,
            "seats": seatsData, // Có đầy đủ row, number, type, price
            "totalAmount": totalAmount,
            "status": "active",
            "purchasedAt": now,
            "qrCodeData": qrData,
            "createdViaSiri": true
        ]
        
        do {
            // Dùng Write Batch để cập nhật đồng thời vé và trạng thái ghế
            let batch = db.batch()
            
            // a. Lưu ticket
            let ticketRef = db.collection("tickets").document(ticketId)
            batch.setData(ticketData, forDocument: ticketRef)
            
            // b. Cập nhật status từng ghế sang "booked"
            for seat in seats {
                let seatRef = db.collection("showtimes")
                    .document(showtimeId)
                    .collection("seats")
                    .document("\(showtimeId)_\(seat.label)")
                batch.updateData(["status": "booked"], forDocument: seatRef)
            }
            
            // c. Trừ số lượng ghế trống khả dụng của showtime
            let showtimeRef = db.collection("showtimes").document(showtimeId)
            batch.updateData([
                "availableSeats": FieldValue.increment(Int64(-seats.count))
            ], forDocument: showtimeRef)
            
            try await batch.commit()
            print("✅ Ticket saved and seats updated successfully: \(ticketId)")
        } catch {
            print("❌ Failed to create ticket or update seats: \(error.localizedDescription)")
        }
    }
    
    
    private func formatVND(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")đ"
    }
}

// MARK: - BookMovieError

@available(iOS 18.0, *)
enum BookMovieError: Error, LocalizedError {
    case insufficientSeats(requested: Int, available: Int)
    case noSeatsAvailable
    
    var errorDescription: String? {
        switch self {
        case .noSeatsAvailable:
            return "Suất chiếu này đã hết toàn bộ ghế. Vui lòng thử lại với suất chiếu khác."
        case .insufficientSeats(let requested, let available):
            if available == 0 {
                return "Rất tiếc, suất chiếu đã hết ghế loại bạn chọn."
            } else {
                return "Suất chiếu chỉ còn \(available) ghế trống, không đủ \(requested) vé bạn yêu cầu."
            }
        }
    }
}

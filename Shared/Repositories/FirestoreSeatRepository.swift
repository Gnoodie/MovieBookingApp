import Foundation
import FirebaseFirestore

/// Implementation thực tế kết nối tới Firebase Firestore cho Seat
/// Xử lý logic đọc và giữ ghế thông qua Firestore Transactions
final class FirestoreSeatRepository: SeatRepositoryProtocol {
    private let db = Firestore.firestore()
    
    // MARK: - SeatRepositoryProtocol
    
    func fetchSeats(showtimeId: String) async throws -> [Seat] {
        let snapshot = try await db.collection("showtimes")
            .document(showtimeId)
            .collection("seats")
            .getDocuments()

        let seats = try snapshot.documents.compactMap { try mapSeat($0) }
        return seats.isEmpty ? generateFallbackSeats(showtimeId: showtimeId) : seats
    }

    func listenToSeats(showtimeId: String) -> AsyncStream<[Seat]> {
        AsyncStream { continuation in
            let listener = db.collection("showtimes")
                .document(showtimeId)
                .collection("seats")
                .addSnapshotListener { snapshot, error in
                    guard let docs = snapshot?.documents, !docs.isEmpty else {
                        continuation.yield(self.generateFallbackSeats(showtimeId: showtimeId))
                        return
                    }
                    let seats = docs.compactMap { doc -> Seat? in
                        do {
                            return try self.mapSeat(doc)
                        } catch {
                            return nil
                        }
                    }
                    if seats.isEmpty {
                        continuation.yield(self.generateFallbackSeats(showtimeId: showtimeId))
                    } else {
                        continuation.yield(seats)
                    }
                }

            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }
    
    func holdSeats(showtimeId: String, seatIds: [String]) async throws -> HoldResponse {
        // Thực hiện Firestore Transaction để đảm bảo không bị race condition khi giữ ghế
        // Production khuyến khích dùng Firebase Cloud Functions để an toàn hơn
        let seatsRef = db.collection("showtimes").document(showtimeId).collection("seats")
        
        return try await db.runTransaction { (transaction, errorPointer) -> Any? in
            var docsToUpdate: [DocumentSnapshot] = []
            
            // 1. ĐỌC TRƯỚC: Lấy trạng thái của tất cả các ghế cần giữ
            for seatId in seatIds {
                let seatDocRef = seatsRef.document(seatId)
                do {
                    let doc = try transaction.getDocument(seatDocRef)
                    docsToUpdate.append(doc)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }
            
            // 2. KIỂM TRA: Xác minh xem có ghế nào đã bị đặt mất không
            for doc in docsToUpdate {
                guard let data = doc.data(),
                      let status = data["status"] as? String else {
                    let err = NSError(domain: "AppError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Dữ liệu ghế không hợp lệ"])
                    errorPointer?.pointee = err
                    return nil
                }
                
                // Nếu không còn 'available', tức là Conflict (409)
                if status != "available" {
                    let err = NSError(domain: "AppError", code: 409, userInfo: [
                        NSLocalizedDescriptionKey: "Ghế đã bị người khác chọn.",
                        "conflictSeatId": doc.documentID
                    ])
                    errorPointer?.pointee = err
                    return nil
                }
            }
            
            // 3. GHI SAU: Tất cả an toàn -> Tiến hành khoá ghế
            // "access_token" là key AuthViewModel dùng để lưu Firebase UID
            let userId = KeychainWrapper.shared.get(forKey: "access_token") ?? "guest"
            let holdId = UUID().uuidString
            // Giữ ghế trong 10 phút
            let expiresAt = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
            
            for doc in docsToUpdate {
                transaction.updateData([
                    "status": "held",
                    "heldBy": userId,
                    "holdId": holdId,
                    "holdExpiresAt": Timestamp(date: expiresAt)
                ], forDocument: doc.reference)
            }
            
            return HoldResponse(holdId: holdId, expiresAt: expiresAt, seatIds: seatIds)
            
        } as! HoldResponse
    }
    
    func releaseSeats(holdId: String) async throws {
        // Giải phóng ghế thông qua Cloud Functions hoặc Backend Job
        // Mock success cho Client (Do client không có showtimeId và seatIds ở params này)
        print("Đã gọi releaseSeats(holdId: \(holdId))")
    }
    
    // MARK: - Private Helpers
    
    private func mapSeat(_ doc: DocumentSnapshot) throws -> Seat {
        guard let data = doc.data() else {
            throw FirestoreRepositoryError.invalidData(docId: doc.documentID)
        }
        
        let id = doc.documentID
        let row = data["row"] as? String ?? ""
        let number = data["number"] as? Int ?? 0
        
        let typeRaw = data["type"] as? String ?? "standard"
        let type = Seat.SeatType(rawValue: typeRaw) ?? .standard
        let priceMultiplier = data["priceMultiplier"] as? Double ?? type.priceMultiplier
        
        // Xác định status, kiểm tra holdExpiresAt nếu ghế đang held
        let statusRaw = data["status"] as? String ?? "available"
        var status = Seat.SeatStatus(rawValue: statusRaw) ?? .available

        if status == .held {
            // Kiểm tra hold đã hết hạn chưa — nếu rồi → coi như available
            if let expiresAt = (data["holdExpiresAt"] as? Timestamp)?.dateValue(),
               expiresAt < Date() {
                // Hold đã hết hạn (server chưa cleanup) → available
                status = .available
            } else {
                // Hold còn hiệu lực — kiểm tra có phải mình đang hold không
                // "access_token" là key AuthViewModel dùng để lưu Firebase UID
                let userId = KeychainWrapper.shared.get(forKey: "access_token") ?? "guest"
                let heldBy = data["heldBy"] as? String
                if heldBy == userId {
                    status = .mine
                }
            }
        }

        let coupleGroupId = data["coupleGroupId"] as? String

        return Seat(id: id, row: row, number: number, type: type, status: status, priceMultiplier: priceMultiplier, coupleGroupId: coupleGroupId)
    }

    /// Helper sinh danh sách ghế dự phòng (5 hàng × 8 ghế) khi Firestore chưa có ghế
    private func generateFallbackSeats(showtimeId: String) -> [Seat] {
        var seats: [Seat] = []
        let rows = ["A", "B", "C", "D", "E"]
        for row in rows {
            for number in 1...8 {
                let id = "\(showtimeId)_\(row)\(number)"
                let isVip = (row == "A" || row == "B")
                let isCouple = (row == "E")
                let type: Seat.SeatType = isVip ? .vip : (isCouple ? .couple : .standard)
                let status: Seat.SeatStatus = (number == 3 && row == "C") ? .booked : .available
                let coupleGroupId = isCouple ? "couple-\(showtimeId)-\(row)-\(ceil(Double(number)/2.0))" : nil

                seats.append(Seat(
                    id: id,
                    row: row,
                    number: number,
                    type: type,
                    status: status,
                    priceMultiplier: type.priceMultiplier,
                    coupleGroupId: coupleGroupId
                ))
            }
        }
        return seats
    }
}

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
            
        return try snapshot.documents.compactMap { try mapSeat($0) }
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
            let userId = KeychainWrapper.shared.get(forKey: "user_id") ?? "guest"
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
        let price = data["price"] as? Int ?? 0
        
        let typeRaw = data["type"] as? String ?? "standard"
        let type = Seat.SeatType(rawValue: typeRaw) ?? .standard
        
        // Xác định status, nếu heldBy là mình thì thành 'mine'
        let statusRaw = data["status"] as? String ?? "available"
        var status = Seat.SeatStatus(rawValue: statusRaw) ?? .available
        
        if status == .held {
            let userId = KeychainWrapper.shared.get(forKey: "user_id") ?? "guest"
            let heldBy = data["heldBy"] as? String
            if heldBy == userId {
                status = .mine
            }
        }
        
        return Seat(id: id, row: row, number: number, type: type, status: status, price: price)
    }
}

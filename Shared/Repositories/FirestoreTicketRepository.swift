import Foundation
import FirebaseFirestore

// MARK: - FirestoreTicketRepository

/// Implementation đọc vé từ Firestore collection "tickets"
final class FirestoreTicketRepository: TicketRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "tickets"

    func fetchMyTickets() async throws -> [Ticket] {
        // "access_token" là key AuthViewModel dùng để lưu Firebase UID
        let userId = KeychainWrapper.shared.get(forKey: "access_token") ?? "guest"
        do {
            // Thử tải từ server trước (online)
            let snapshot = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "showtime", descending: true)
                .limit(to: 100)
                .getDocuments(source: .default)
            return snapshot.documents.compactMap { mapTicket($0) }
        } catch {
            // Mất mạng -> tải trực tiếp từ local offline cache của Firestore
            print("🌐 [Offline Mode] Network failed. Fetching tickets from local Firestore cache.")
            if let snapshot = try? await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "showtime", descending: true)
                .limit(to: 100)
                .getDocuments(source: .cache) {
                return snapshot.documents.compactMap { mapTicket($0) }
            }
            throw error
        }
    }

    func fetchTicketDetail(id: String) async throws -> Ticket {
        do {
            let doc = try await db.collection(collection).document(id).getDocument(source: .default)
            guard doc.exists, let ticket = mapTicket(doc) else {
                throw FirestoreRepositoryError.documentNotFound(id: id)
            }
            return ticket
        } catch {
            // Mất mạng -> tải chi tiết từ local cache
            print("🌐 [Offline Mode] Fetching single ticket from local Firestore cache.")
            if let doc = try? await db.collection(collection).document(id).getDocument(source: .cache),
               doc.exists, let ticket = mapTicket(doc) {
                return ticket
            }
            throw error
        }
    }

    func cancelTicket(id: String) async throws {
        try await db.collection(collection).document(id).updateData([
            "status": Ticket.TicketStatus.cancelled.rawValue
        ])
    }

    // MARK: - Private Mapper

    private func mapTicket(_ doc: DocumentSnapshot) -> Ticket? {
        guard let data = doc.data() else { return nil }

        let bookingId = data["bookingId"] as? String ?? doc.documentID
        let movieTitle = data["movieTitle"] as? String ?? ""
        let moviePosterURL = (data["moviePosterURL"] as? String).flatMap { URL(string: $0) }
        let cinemaName = data["cinemaName"] as? String ?? ""
        let cinemaAddress = data["cinemaAddress"] as? String ?? ""
        let hallName = data["hallName"] as? String ?? ""
        let showtime = (data["showtime"] as? Timestamp)?.dateValue() ?? Date()
        let format = data["format"] as? String ?? "2D"
        let language = data["language"] as? String ?? "VI"
        let totalAmount = Decimal((data["totalAmount"] as? Double) ?? 0)
        let statusRaw = data["status"] as? String ?? "active"
        let status = Ticket.TicketStatus(rawValue: statusRaw) ?? .active
        let purchasedAt = (data["purchasedAt"] as? Timestamp)?.dateValue() ?? Date()
        let qrCodeData = data["qrCodeData"] as? String ?? bookingId
        let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue()

        let seatsRaw = data["seats"] as? [[String: Any]] ?? []
        let seats: [Ticket.BookedSeat] = seatsRaw.compactMap { s in
            guard let row = s["row"] as? String,
                  let number = s["number"] as? Int,
                  let type = s["type"] as? String,
                  let price = s["price"] as? Double else { return nil }
            return Ticket.BookedSeat(row: row, number: number, type: type, price: Decimal(price))
        }

        return Ticket(
            id: doc.documentID,
            bookingId: bookingId,
            movieTitle: movieTitle,
            moviePosterURL: moviePosterURL,
            cinemaName: cinemaName,
            cinemaAddress: cinemaAddress,
            hallName: hallName,
            showtime: showtime,
            format: format,
            language: language,
            seats: seats,
            totalAmount: totalAmount,
            status: status,
            purchasedAt: purchasedAt,
            qrCodeData: qrCodeData,
            expiresAt: expiresAt
        )
    }
}

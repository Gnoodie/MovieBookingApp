import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - OrderRepositoryProtocol

protocol OrderRepositoryProtocol {
    func createOrder(
        seats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        discountAmount: Decimal,
        paymentMethod: PaymentMethod,
        paymentReference: String?
    ) async throws -> (order: Order, ticket: Ticket)

    func fetchMyOrders() async throws -> [Order]
    func fetchOrderDetail(id: String) async throws -> Order
}

// MARK: - FirestoreOrderRepository

/// Tạo đơn hàng và vé thông qua Firestore Transaction
/// Đảm bảo atomicity: ghế held → booked, tạo order + ticket cùng lúc
final class FirestoreOrderRepository: OrderRepositoryProtocol {
    private let db = Firestore.firestore()

    // MARK: - createOrder (Transaction)

    func createOrder(
        seats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        discountAmount: Decimal,
        paymentMethod: PaymentMethod,
        paymentReference: String?
    ) async throws -> (order: Order, ticket: Ticket) {

        // "access_token" là key AuthViewModel dùng để lưu Firebase UID
        let userId = Auth.auth().currentUser?.uid ?? KeychainWrapper.shared.get(forKey: "access_token") ?? "guest"
        let orderId = UUID().uuidString
        let ticketId = UUID().uuidString
        let bookingCode = String(orderId.prefix(9).uppercased())
        let now = Date()

        // Tính giá
        let subtotalTicket = seats.reduce(Decimal(0)) { $0 + $1.price(basePrice: showtime.basePrice) }
        let formatSurcharge = showtime.format.surcharge * Decimal(seats.count)
        let subtotalFnB = fnbItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
        let total = subtotalTicket + formatSurcharge + subtotalFnB - discountAmount

        let seatsRef = db.collection("showtimes").document(showtime.id).collection("seats")
        let ordersRef = db.collection("orders").document(orderId)
        let ticketsRef = db.collection("tickets").document(ticketId)

        // Thực hiện Transaction
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            // 1. ĐỌC: Kiểm tra tất cả ghế vẫn còn ở trạng thái 'held' bởi user này
            for seat in seats {
                let seatRef = seatsRef.document(seat.id)
                let seatDoc: DocumentSnapshot
                do {
                    seatDoc = try transaction.getDocument(seatRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                guard let data = seatDoc.data(),
                      let status = data["status"] as? String,
                      let heldBy = data["heldBy"] as? String else {
                    let err = NSError(domain: "OrderError", code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Dữ liệu ghế \(seat.displayName) không hợp lệ."])
                    errorPointer?.pointee = err
                    return nil
                }

                // Ghế phải đang held bởi chính user này
                if status != "held" || heldBy != userId {
                    let err = NSError(domain: "OrderError", code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "Ghế \(seat.displayName) không còn được giữ. Vui lòng chọn lại."])
                    errorPointer?.pointee = err
                    return nil
                }
            }

            // 2. GHI: Chuyển tất cả ghế sang 'booked'
            for seat in seats {
                let seatRef = seatsRef.document(seat.id)
                transaction.updateData([
                    "status": "booked",
                    "bookedByOrderId": orderId,
                    "bookedAt": Timestamp(date: now)
                ], forDocument: seatRef)
            }

            // 3. GHI: Tạo Order document
            let bookedSeatsData: [[String: Any]] = seats.map { seat in
                [
                    "row": seat.row,
                    "number": seat.number,
                    "type": seat.type.rawValue,
                    "price": NSDecimalNumber(decimal: seat.price(basePrice: showtime.basePrice)).doubleValue
                ]
            }
            let fnbData: [[String: Any]] = fnbItems.map { item in
                [
                    "itemId": item.itemId,
                    "name": item.name,
                    "quantity": item.quantity,
                    "unitPrice": NSDecimalNumber(decimal: item.unitPrice).doubleValue
                ]
            }

            let orderData: [String: Any] = [
                "userId": userId,
                "movieId": movie.id,
                "movieTitle": movie.title,
                "moviePosterURL": movie.posterURL?.absoluteString ?? "",
                "cinemaName": showtime.cinemaName,
                "hallName": showtime.hallName,
                "showtime": Timestamp(date: showtime.startTime),
                "format": showtime.format.rawValue,
                "seats": bookedSeatsData,
                "fnbItems": fnbData,
                "subtotalTicket": NSDecimalNumber(decimal: subtotalTicket).doubleValue,
                "subtotalFnB": NSDecimalNumber(decimal: subtotalFnB).doubleValue,
                "formatSurcharge": NSDecimalNumber(decimal: formatSurcharge).doubleValue,
                "discountAmount": NSDecimalNumber(decimal: discountAmount).doubleValue,
                "totalAmount": NSDecimalNumber(decimal: total).doubleValue,
                "paymentMethod": paymentMethod.rawValue,
                "paymentReference": paymentReference ?? "",
                "status": OrderStatus.paid.rawValue,
                "createdAt": Timestamp(date: now),
                "ticketId": ticketId
            ]
            transaction.setData(orderData, forDocument: ordersRef)

            // 4. GHI: Tạo Ticket document
            let qrContent = "MBK|\(bookingCode)|\(showtime.id)|\(seats.map(\.displayName).joined(separator: ","))|\(Int(now.timeIntervalSince1970))"
            let ticketData: [String: Any] = [
                "bookingId": bookingCode,
                "orderId": orderId,
                "userId": userId,
                "movieTitle": movie.title,
                "moviePosterURL": movie.posterURL?.absoluteString ?? "",
                "cinemaName": showtime.cinemaName,
                "cinemaAddress": "",
                "hallName": showtime.hallName,
                "showtime": Timestamp(date: showtime.startTime),
                "format": showtime.format.rawValue,
                "language": showtime.language.rawValue,
                "seats": bookedSeatsData,
                "totalAmount": NSDecimalNumber(decimal: total).doubleValue,
                "status": Ticket.TicketStatus.active.rawValue,
                "purchasedAt": Timestamp(date: now),
                "qrCodeData": qrContent
            ]
            transaction.setData(ticketData, forDocument: ticketsRef)

            return true
        }

        // Build local objects để trả về ngay (không cần round-trip fetch)
        let bookedSeats = seats.map { seat in
            BookedSeatInfo(
                row: seat.row,
                number: seat.number,
                type: seat.type.rawValue,
                price: seat.price(basePrice: showtime.basePrice)
            )
        }

        let order = Order(
            id: orderId,
            userId: userId,
            movieId: movie.id,
            movieTitle: movie.title,
            moviePosterURL: movie.posterURL,
            cinemaName: showtime.cinemaName,
            hallName: showtime.hallName,
            showtime: showtime.startTime,
            format: showtime.format.rawValue,
            seats: bookedSeats,
            fnbItems: fnbItems,
            subtotalTicket: subtotalTicket,
            subtotalFnB: subtotalFnB,
            formatSurcharge: formatSurcharge,
            discountAmount: discountAmount,
            totalAmount: total,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference,
            status: .paid,
            createdAt: now
        )

        let qrContent = "MBK|\(bookingCode)|\(showtime.id)|\(seats.map(\.displayName).joined(separator: ","))|\(Int(now.timeIntervalSince1970))"
        let ticket = Ticket(
            id: ticketId,
            bookingId: bookingCode,
            movieTitle: movie.title,
            moviePosterURL: movie.posterURL,
            cinemaName: showtime.cinemaName,
            cinemaAddress: "",
            hallName: showtime.hallName,
            showtime: showtime.startTime,
            format: showtime.format.rawValue,
            language: showtime.language.rawValue,
            seats: seats.map { seat in
                Ticket.BookedSeat(
                    row: seat.row,
                    number: seat.number,
                    type: seat.type.rawValue,
                    price: seat.price(basePrice: showtime.basePrice)
                )
            },
            totalAmount: total,
            status: .active,
            purchasedAt: now,
            qrCodeData: qrContent,
            expiresAt: nil
        )

        return (order, ticket)
    }

    // MARK: - fetchMyOrders

    func fetchMyOrders() async throws -> [Order] {
        // Ưu tiên UID từ phiên đăng nhập Firebase Auth
        let userId = Auth.auth().currentUser?.uid ?? KeychainWrapper.shared.get(forKey: "access_token") ?? "guest"
        let snapshot = try await db.collection("orders")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { mapOrder($0) }
    }

    // MARK: - fetchOrderDetail

    func fetchOrderDetail(id: String) async throws -> Order {
        let doc = try await db.collection("orders").document(id).getDocument()
        guard doc.exists, let order = mapOrder(doc) else {
            throw FirestoreRepositoryError.documentNotFound(id: id)
        }
        return order
    }

    // MARK: - Private Mapper

    private func mapOrder(_ doc: DocumentSnapshot) -> Order? {
        guard let data = doc.data() else { return nil }

        let userId = data["userId"] as? String ?? ""
        let movieId = data["movieId"] as? String ?? ""
        let movieTitle = data["movieTitle"] as? String ?? ""
        let moviePosterURL = (data["moviePosterURL"] as? String).flatMap { URL(string: $0) }
        let cinemaName = data["cinemaName"] as? String ?? ""
        let hallName = data["hallName"] as? String ?? ""
        let showtime = (data["showtime"] as? Timestamp)?.dateValue() ?? Date()
        let format = data["format"] as? String ?? "2D"
        let subtotalTicket = Decimal((data["subtotalTicket"] as? Double) ?? 0)
        let subtotalFnB = Decimal((data["subtotalFnB"] as? Double) ?? 0)
        let formatSurcharge = Decimal((data["formatSurcharge"] as? Double) ?? 0)
        let discountAmount = Decimal((data["discountAmount"] as? Double) ?? 0)
        let totalAmount = Decimal((data["totalAmount"] as? Double) ?? 0)
        let paymentMethodRaw = data["paymentMethod"] as? String ?? "mock_pay"
        let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw) ?? .mockPay
        let paymentReference = data["paymentReference"] as? String
        let statusRaw = data["status"] as? String ?? "paid"
        let status = OrderStatus(rawValue: statusRaw) ?? .paid
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        let seatsRaw = data["seats"] as? [[String: Any]] ?? []
        let seats: [BookedSeatInfo] = seatsRaw.compactMap { s in
            guard let row = s["row"] as? String,
                  let number = s["number"] as? Int,
                  let type = s["type"] as? String,
                  let price = s["price"] as? Double else { return nil }
            return BookedSeatInfo(row: row, number: number, type: type, price: Decimal(price))
        }

        let fnbRaw = data["fnbItems"] as? [[String: Any]] ?? []
        let fnbItems: [FnBOrderItem] = fnbRaw.compactMap { f in
            guard let itemId = f["itemId"] as? String,
                  let name = f["name"] as? String,
                  let quantity = f["quantity"] as? Int,
                  let unitPrice = f["unitPrice"] as? Double else { return nil }
            return FnBOrderItem(itemId: itemId, name: name, quantity: quantity, unitPrice: Decimal(unitPrice))
        }

        return Order(
            id: doc.documentID,
            userId: userId,
            movieId: movieId,
            movieTitle: movieTitle,
            moviePosterURL: moviePosterURL,
            cinemaName: cinemaName,
            hallName: hallName,
            showtime: showtime,
            format: format,
            seats: seats,
            fnbItems: fnbItems,
            subtotalTicket: subtotalTicket,
            subtotalFnB: subtotalFnB,
            formatSurcharge: formatSurcharge,
            discountAmount: discountAmount,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference,
            status: status,
            createdAt: createdAt
        )
    }
}

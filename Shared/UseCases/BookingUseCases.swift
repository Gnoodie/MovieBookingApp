import Foundation

// MARK: - BookTicketUseCase

/// Use Case điều phối toàn bộ luồng đặt vé:
/// Hold seats → Payment → Create Order → Ticket
///
/// Đây là layer trung gian giữa ViewModel và Repositories.
/// Giúp ViewModel gọn hơn và logic dễ test hơn.
///
/// Hiện tại CheckoutViewModel gọi trực tiếp repository — use case này
/// là chuẩn bị cho khi refactor Sprint 5.
protocol BookTicketUseCaseProtocol {
    func execute(
        seats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        discountAmount: Decimal,
        paymentMethod: PaymentMethod
    ) async throws -> (order: Order, ticket: Ticket)
}

/// Concrete implementation — gọi PaymentService rồi OrderRepository
final class BookTicketUseCase: BookTicketUseCaseProtocol {
    private let paymentService: PaymentService
    private let orderRepository: OrderRepositoryProtocol

    init(
        paymentService: PaymentService = .shared,
        orderRepository: OrderRepositoryProtocol = FirestoreOrderRepository()
    ) {
        self.paymentService = paymentService
        self.orderRepository = orderRepository
    }

    func execute(
        seats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        discountAmount: Decimal,
        paymentMethod: PaymentMethod
    ) async throws -> (order: Order, ticket: Ticket) {
        let totalAmount = seats.reduce(Decimal(0)) { $0 + $1.price(basePrice: showtime.basePrice) }
            + showtime.format.surcharge * Decimal(seats.count)
            + fnbItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
            - discountAmount

        let pendingOrder = PendingOrderInfo(
            orderId: UUID().uuidString,
            movieTitle: movie.title,
            totalAmount: max(0, totalAmount)
        )

        let paymentResult = await paymentService.pay(method: paymentMethod, order: pendingOrder)

        switch paymentResult {
        case .success(let reference):
            return try await orderRepository.createOrder(
                seats: seats,
                showtime: showtime,
                movie: movie,
                fnbItems: fnbItems,
                discountAmount: discountAmount,
                paymentMethod: paymentMethod,
                paymentReference: reference
            )
        case .failure(let message):
            throw BookTicketError.paymentFailed(message)
        case .cancelled:
            throw BookTicketError.paymentCancelled
        }
    }
}

// MARK: - FetchMyTicketsUseCase

/// Use Case lấy danh sách vé và phân loại Active / History
protocol FetchMyTicketsUseCaseProtocol {
    func execute() async throws -> (active: [Ticket], history: [Ticket])
}

final class FetchMyTicketsUseCase: FetchMyTicketsUseCaseProtocol {
    private let ticketRepository: TicketRepositoryProtocol

    init(ticketRepository: TicketRepositoryProtocol = FirestoreTicketRepository()) {
        self.ticketRepository = ticketRepository
    }

    func execute() async throws -> (active: [Ticket], history: [Ticket]) {
        let tickets = try await ticketRepository.fetchMyTickets()
        let now = Date()
        let cutoff = now.addingTimeInterval(-3 * 3600) // Còn tính là active trong 3h sau giờ chiếu

        let active = tickets
            .filter { $0.status == .active && $0.showtime > cutoff }
            .sorted { $0.showtime < $1.showtime }

        let history = tickets
            .filter { !($0.status == .active && $0.showtime > cutoff) }
            .sorted { $0.showtime > $1.showtime }

        return (active, history)
    }
}

// MARK: - BookTicketError

enum BookTicketError: LocalizedError {
    case paymentFailed(String)
    case paymentCancelled
    case seatConflict(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .paymentFailed(let msg):  return "Thanh toán thất bại: \(msg)"
        case .paymentCancelled:        return "Bạn đã huỷ thanh toán."
        case .seatConflict(let seat):  return "Ghế \(seat) đã được người khác đặt."
        case .unknown:                 return "Đã xảy ra lỗi không xác định."
        }
    }
}

import Foundation

// MARK: - CheckoutViewModel

/// ViewModel cho màn hình Checkout (Phase 3)
/// Tính giá, áp voucher, xử lý thanh toán qua PaymentService + OrderRepository
@MainActor
final class CheckoutViewModel: ObservableObject {

    // MARK: - Input (từ SeatMap + FnB)

    let selectedSeats: [Seat]
    let showtime: Showtime
    let movie: Movie
    let fnbItems: [FnBOrderItem]

    // MARK: - Published State

    @Published var voucherCode: String = ""
    @Published var discountAmount: Decimal = 0
    @Published var voucherError: String? = nil
    @Published var voucherApplied: Bool = false

    @Published var selectedPaymentMethod: PaymentMethod = .mockPay
    @Published var isProcessingPayment: Bool = false
    @Published var paymentError: String? = nil

    /// Trigger navigation sang BookingSuccessView khi thanh toán thành công
    @Published var paymentSuccess: Bool = false
    @Published var completedOrder: Order? = nil
    @Published var completedTicket: Ticket? = nil

    // MARK: - Dependencies

    private let orderRepository: OrderRepositoryProtocol
    private let paymentService: PaymentService

    // MARK: - Init

    init(
        selectedSeats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        orderRepository: OrderRepositoryProtocol = FirestoreOrderRepository(),
        paymentService: PaymentService = .shared
    ) {
        self.selectedSeats = selectedSeats
        self.showtime = showtime
        self.movie = movie
        self.fnbItems = fnbItems
        self.orderRepository = orderRepository
        self.paymentService = paymentService
    }

    // MARK: - Computed Properties

    /// Tổng giá vé (basePrice × priceMultiplier cho mỗi ghế)
    var subtotalTicket: Decimal {
        selectedSeats.reduce(Decimal(0)) { $0 + $1.price(basePrice: showtime.basePrice) }
    }

    /// Phụ thu format (IMAX, 4DX...) × số ghế
    var formatSurcharge: Decimal {
        showtime.format.surcharge * Decimal(selectedSeats.count)
    }

    /// Tổng F&B
    var subtotalFnB: Decimal {
        fnbItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }

    /// Tổng trước giảm giá
    var totalBeforeDiscount: Decimal {
        subtotalTicket + formatSurcharge + subtotalFnB
    }

    /// Tổng sau giảm giá
    var totalAfterDiscount: Decimal {
        max(0, totalBeforeDiscount - discountAmount)
    }

    /// Tổng tiền đã format ("495.000đ")
    var formattedTotal: String {
        Self.formatVND(totalAfterDiscount)
    }

    /// Danh sách ghế dạng text ("E7, E8")
    var seatLabels: String {
        selectedSeats.map(\.displayName).joined(separator: ", ")
    }

    /// Có thể thanh toán hay không
    var canPay: Bool {
        !isProcessingPayment
            && selectedPaymentMethod.isAvailable
            && !selectedSeats.isEmpty
    }

    /// Có F&B hay không
    var hasFnB: Bool { !fnbItems.isEmpty }

    /// Label phụ thu format
    var formatSurchargeLabel: String {
        "Phụ thu \(showtime.format.badge) (×\(selectedSeats.count))"
    }

    // MARK: - Actions

    /// Áp dụng voucher — hardcode 2 mã demo
    func applyVoucher() {
        let code = voucherCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !voucherApplied else {
            voucherError = "Đã áp dụng voucher"
            return
        }
        guard !code.isEmpty else {
            voucherError = "Vui lòng nhập mã voucher"
            return
        }

        switch code {
        case "WELCOME50":
            discountAmount = 50_000
            voucherApplied = true
            voucherError = nil
        case "MOVIE20":
            discountAmount = totalBeforeDiscount * Decimal(0.2)
            voucherApplied = true
            voucherError = nil
        default:
            discountAmount = 0
            voucherApplied = false
            voucherError = "Mã voucher không hợp lệ"
        }
    }

    /// Xóa voucher đã áp dụng
    func removeVoucher() {
        voucherCode = ""
        discountAmount = 0
        voucherApplied = false
        voucherError = nil
    }

    /// Chọn phương thức thanh toán
    func selectPaymentMethod(_ method: PaymentMethod) {
        guard method.isAvailable else { return }
        selectedPaymentMethod = method
    }

    /// Xử lý thanh toán đầy đủ:
    /// PaymentService.pay → OrderRepository.createOrder → navigate success
    func processPayment() {
        guard canPay else { return }

        isProcessingPayment = true
        paymentError = nil

        Task {
            // 1. Gọi PaymentService
            let pendingOrder = PendingOrderInfo(
                orderId: UUID().uuidString,
                movieTitle: movie.title,
                totalAmount: totalAfterDiscount
            )

            let result = await paymentService.pay(
                method: selectedPaymentMethod,
                order: pendingOrder
            )

            switch result {
            case .success(let reference):
                // 2. Tạo Order + Ticket qua Firestore Transaction
                do {
                    let (order, ticket) = try await orderRepository.createOrder(
                        seats: selectedSeats,
                        showtime: showtime,
                        movie: movie,
                        fnbItems: fnbItems,
                        discountAmount: discountAmount,
                        paymentMethod: selectedPaymentMethod,
                        paymentReference: reference
                    )

                    self.completedOrder = order
                    self.completedTicket = ticket
                    self.paymentSuccess = true

                } catch {
                    self.paymentError = error.localizedDescription
                }

            case .failure(let message):
                self.paymentError = message

            case .cancelled:
                // User huỷ — không làm gì
                break
            }

            self.isProcessingPayment = false
        }
    }

    // MARK: - Static Helpers

    /// NumberFormatter được cache — không tạo mới mỗi lần gọi
    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Format số tiền theo VND: "150.000đ"
    static func formatVND(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        return (vndFormatter.string(from: number) ?? "\(amount)") + "đ"
    }
}

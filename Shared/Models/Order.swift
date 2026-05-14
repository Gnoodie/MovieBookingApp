import Foundation

// MARK: - PaymentMethod

enum PaymentMethod: String, Codable, CaseIterable {
    case applePay = "apple_pay"
    case momo     = "momo"
    case vnpay    = "vnpay"
    case mockPay  = "mock_pay"   // Chỉ dùng trong Debug / Dev

    var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .momo:     return "MoMo"
        case .vnpay:    return "VNPay"
        case .mockPay:  return "Thanh toán thử (Dev)"
        }
    }

    var icon: String {
        switch self {
        case .applePay: return "🍎"
        case .momo:     return "💜"
        case .vnpay:    return "🔵"
        case .mockPay:  return "🧪"
        }
    }

    /// Apple Pay cần enrollment — disable trong môi trường dev hiện tại
    var isAvailable: Bool {
        switch self {
        case .applePay: return false
        case .momo, .vnpay, .mockPay: return true
        }
    }
}

// MARK: - OrderStatus

enum OrderStatus: String, Codable {
    case pending    = "pending"
    case paid       = "paid"
    case cancelled  = "cancelled"
    case refunded   = "refunded"

    var displayLabel: String {
        switch self {
        case .pending:   return "Chờ thanh toán"
        case .paid:      return "Đã thanh toán"
        case .cancelled: return "Đã hủy"
        case .refunded:  return "Đã hoàn tiền"
        }
    }
}

// MARK: - Order

/// Đơn hàng đã được xác nhận thanh toán
struct Order: Identifiable, Codable, Hashable {

    static func == (lhs: Order, rhs: Order) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }


    let id: String
    let userId: String
    // Snapshot thông tin phim / suất (không bị ảnh hưởng khi data gốc thay đổi)
    let movieId: String
    let movieTitle: String
    let moviePosterURL: URL?
    let cinemaName: String
    let hallName: String
    let showtime: Date
    let format: String
    // Chi tiết ghế
    let seats: [BookedSeatInfo]
    // F&B
    let fnbItems: [FnBOrderItem]
    // Giá
    let subtotalTicket: Decimal
    let subtotalFnB: Decimal
    let formatSurcharge: Decimal
    let discountAmount: Decimal
    let totalAmount: Decimal
    // Thanh toán
    let paymentMethod: PaymentMethod
    let paymentReference: String?   // Transaction ID từ MoMo/VNPay
    let status: OrderStatus
    let createdAt: Date

    // MARK: - Computed

    var ticketId: String { id }   // 1 order = 1 ticket trong scope hiện tại

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let number = NSDecimalNumber(decimal: totalAmount)
        return (formatter.string(from: number) ?? "\(totalAmount)") + "đ"
    }

    var seatLabels: String {
        seats.map { "\($0.row)\($0.number)" }.joined(separator: ", ")
    }
}

// MARK: - BookedSeatInfo

/// Snapshot thông tin ghế tại thời điểm đặt vé
struct BookedSeatInfo: Codable, Equatable, Identifiable {
    var id: String { "\(row)\(number)" }
    let row: String
    let number: Int
    let type: String        // "standard", "vip", "couple"
    let price: Decimal

    var displayName: String { "\(row)\(number)" }
}

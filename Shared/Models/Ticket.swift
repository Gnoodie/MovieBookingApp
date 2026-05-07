import Foundation

// MARK: - Ticket

/// Entity đại diện cho một vé đã mua thành công
public struct Ticket: Identifiable, Equatable, Codable {
    public let id: String                  // UUID của vé
    public let bookingId: String           // Mã đặt chỗ (hiển thị cho người dùng)
    public let movieTitle: String          // Snapshot — không thay đổi dù movie data thay đổi
    public let moviePosterURL: URL?
    public let cinemaName: String
    public let cinemaAddress: String
    public let hallName: String
    public let showtime: Date
    public let format: String              // "IMAX", "2D"...
    public let language: String            // "VI", "EN"...
    public let seats: [BookedSeat]
    public let totalAmount: Decimal
    public let status: TicketStatus
    public let purchasedAt: Date
    public let qrCodeData: String          // String encode vào QR — dùng để soát vé tại rạp
    public let expiresAt: Date?            // Nếu là vé có hạn (presale)

    // MARK: - Computed Properties

    /// Mã đặt chỗ định dạng đẹp: "MBK-2024-001234"
    public var displayBookingId: String {
        "MBK-\(bookingId.uppercased())"
    }

    /// Danh sách tên ghế: "A5, A6, A7"
    public var seatLabels: String {
        seats.map(\.displayName).joined(separator: ", ")
    }

    /// Số lượng vé
    public var ticketCount: Int { seats.count }

    public var isActive: Bool { status == .active }

    // MARK: - Nested Types

    public struct BookedSeat: Equatable, Codable, Identifiable {
        public var id: String { "\(row)\(number)" }
        public let row: String
        let number: Int
        let type: String            // "Standard", "VIP", "Couple"
        let price: Decimal

        var displayName: String { "\(row)\(number)" }
    }

    public enum TicketStatus: String, Codable, CaseIterable {
        case active    = "active"    // Vé hợp lệ, chưa dùng
        case used      = "used"      // Đã soát vé vào rạp
        case cancelled = "cancelled" // Đã hủy, có thể được hoàn tiền
        case expired   = "expired"   // Quá hạn sử dụng

        var displayLabel: String {
            switch self {
            case .active:    return "Hợp lệ"
            case .used:      return "Đã sử dụng"
            case .cancelled: return "Đã hủy"
            case .expired:   return "Hết hạn"
            }
        }

        var isUsable: Bool { self == .active }
    }
}

// MARK: - Booking (Transient — dùng trong quá trình đặt vé)

/// Trạng thái đặt vé đang trong quá trình — chưa thanh toán
struct BookingSession: Equatable {
    let showtimeId: String
    let holdId: String              // ID từ server khi hold ghế
    let selectedSeats: [Seat]
    let basePrice: Decimal
    let formatSurcharge: Decimal
    let expiresAt: Date             // Hold hết hạn sau 10 phút

    var subtotal: Decimal {
        selectedSeats.reduce(Decimal(0)) { $0 + $1.price(basePrice: basePrice) }
    }

    var totalAmount: Decimal {
        subtotal + formatSurcharge * Decimal(selectedSeats.count)
    }

    var remainingSeconds: Int {
        max(0, Int(expiresAt.timeIntervalSinceNow))
    }

    var isExpired: Bool { remainingSeconds == 0 }
}

// MARK: - Mock Data

extension Ticket {
    static let mocks: [Ticket] = [
        Ticket(
            id: UUID().uuidString,
            bookingId: "abc123def",
            movieTitle: "Người Nhện: Vũ Trụ Mới",
            moviePosterURL: URL(string: "https://picsum.photos/seed/movie1/400/600"),
            cinemaName: "CGV Vincom Center Bà Triệu",
            cinemaAddress: "191 Bà Triệu, Hai Bà Trưng, Hà Nội",
            hallName: "Phòng 1 - IMAX",
            showtime: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            format: "IMAX",
            language: "EN",
            seats: [
                BookedSeat(row: "E", number: 7, type: "Standard", price: 150_000),
                BookedSeat(row: "E", number: 8, type: "Standard", price: 150_000),
            ],
            totalAmount: 300_000,
            status: .active,
            purchasedAt: Date(),
            qrCodeData: "MBK|abc123def|show-001|E7,E8|2024",
            expiresAt: nil
        ),
        Ticket(
            id: UUID().uuidString,
            bookingId: "xyz789ghi",
            movieTitle: "Dune: Phần Hai",
            moviePosterURL: URL(string: "https://picsum.photos/seed/movie3/400/600"),
            cinemaName: "Lotte Cinema Landmark 81",
            cinemaAddress: "772A Điện Biên Phủ, Bình Thạnh, TP.HCM",
            hallName: "Phòng 1 - Dolby Atmos",
            showtime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            format: "Dolby",
            language: "EN",
            seats: [
                BookedSeat(row: "G", number: 5, type: "VIP", price: 225_000),
            ],
            totalAmount: 225_000,
            status: .used,
            purchasedAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            qrCodeData: "MBK|xyz789ghi|show-002|G5|2024",
            expiresAt: nil
        ),
    ]
}

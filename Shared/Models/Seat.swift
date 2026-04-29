import Foundation

// MARK: - Seat

/// Entity đại diện cho một ghế trong phòng chiếu
struct Seat: Identifiable, Equatable, Hashable, Codable {
    let id: String                  // "A5", "B12" — unique trong showtime
    let row: String                 // "A", "B", ... "L"
    let number: Int                 // 1, 2, ... 16
    let type: SeatType
    var status: SeatStatus
    let priceMultiplier: Double     // 1.0 = thường, 1.5 = VIP, 2.0 = Couple

    // MARK: - Computed Properties

    /// Tên ghế hiển thị trên UI: "A5", "B12"
    var displayName: String { "\(row)\(number)" }

    /// Giá ghế = giá cơ bản showtime × priceMultiplier
    func price(basePrice: Decimal) -> Decimal {
        basePrice * Decimal(priceMultiplier)
    }

    /// Ghế có thể được chọn bởi người dùng không
    var isSelectable: Bool { status == .available }

    // MARK: - Nested Types

    enum SeatType: String, Codable, CaseIterable {
        case standard   = "standard"    // Ghế thường
        case vip        = "vip"         // Ghế VIP (hàng đầu khu vực VIP)
        case couple     = "couple"      // Ghế đôi (2 ghế liền, không tay vịn giữa)
        case wheelchair = "wheelchair"  // Ghế dành cho người khuyết tật
        case unavailable = "unavailable" // Lối đi / cột — không phải ghế

        var priceMultiplier: Double {
            switch self {
            case .standard:    return 1.0
            case .vip:         return 1.5
            case .couple:      return 2.0
            case .wheelchair:  return 1.0
            case .unavailable: return 0.0
            }
        }
    }

    enum SeatStatus: String, Codable, CaseIterable {
        case available    = "available"    // Trống — user có thể chọn
        case held         = "held"         // Người khác đang giữ (SSE báo)
        case mine         = "mine"         // Tôi đang giữ trong session này
        case booked       = "booked"       // Đã bán — không thể chọn
        case unavailable  = "unavailable"  // Lối đi / cột — không hiển thị như ghế
    }
}

// MARK: - SeatMap

/// Toàn bộ bản đồ ghế của một suất chiếu
struct SeatMap: Equatable, Codable {
    let showtimeId: String
    let rows: [String]              // ["A","B","C","D","E","F","G","H"]
    let seats: [Seat]               // Flat array — filter theo row khi render
    let screenLabel: String         // "MÀN HÌNH" hiển thị phía trên sơ đồ

    /// Ghế theo hàng để render từng row
    func seats(inRow row: String) -> [Seat] {
        seats.filter { $0.row == row }.sorted { $0.number < $1.number }
    }

    /// Tổng số ghế còn trống
    var availableCount: Int {
        seats.filter { $0.status == .available }.count
    }

    /// Ghế tôi đang giữ trong session
    var mySeats: [Seat] {
        seats.filter { $0.status == .mine }
    }
}

// MARK: - Mock Data

extension SeatMap {
    /// Tạo bản đồ ghế mẫu 8 hàng × 12 ghế
    static func mock(showtimeId: String) -> SeatMap {
        let rows = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let seatsPerRow = 12
        var seats: [Seat] = []

        for (rowIndex, row) in rows.enumerated() {
            for number in 1...seatsPerRow {
                // Xác định loại ghế
                let type: Seat.SeatType
                if rowIndex <= 1 {
                    type = .vip             // 2 hàng đầu: VIP
                } else if number == 6 || number == 7 {
                    // Giữa hàng cuối: couple seats
                    type = rowIndex == rows.count - 1 ? .couple : .standard
                } else {
                    type = .standard
                }

                // Giả lập trạng thái ngẫu nhiên để preview
                let status: Seat.SeatStatus
                let randomVal = (rowIndex * seatsPerRow + number) % 7
                switch randomVal {
                case 0:    status = .booked
                case 1:    status = .held
                case 2, 3: status = .available
                default:   status = .available
                }

                seats.append(Seat(
                    id: "\(row)\(number)",
                    row: row,
                    number: number,
                    type: type,
                    status: status,
                    priceMultiplier: type.priceMultiplier
                ))
            }
        }

        return SeatMap(
            showtimeId: showtimeId,
            rows: rows,
            seats: seats,
            screenLabel: "MÀN HÌNH"
        )
    }
}

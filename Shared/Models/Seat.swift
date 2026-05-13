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

    /// ID nhóm cặp ghế đôi — 2 ghế cùng cặp có cùng giá trị này.
    /// Ví dụ: E1+E2 → "E-couple-1", E3+E4 → "E-couple-2"
    /// nil nếu không phải ghế couple.
    let coupleGroupId: String?

    // MARK: - Computed Properties

    var displayName: String { "\(row)\(number)" }

    func price(basePrice: Decimal) -> Decimal {
        basePrice * Decimal(priceMultiplier)
    }

    var isSelectable: Bool { status == .available }

    // MARK: - Nested Types

    enum SeatType: String, Codable, CaseIterable {
        case standard    = "standard"
        case vip         = "vip"
        case couple      = "couple"
        case wheelchair  = "wheelchair"
        case unavailable = "unavailable"

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
        case available   = "available"
        case held        = "held"
        case mine        = "mine"
        case booked      = "booked"
        case unavailable = "unavailable"
    }

    // MARK: - CodingKeys
    // Cần khai báo để coupleGroupId optional không làm crash khi decode
    // document Firestore cũ chưa có field này
    enum CodingKeys: String, CodingKey {
        case id, row, number, type, status, priceMultiplier, coupleGroupId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id              = try container.decode(String.self,       forKey: .id)
        row             = try container.decode(String.self,       forKey: .row)
        number          = try container.decode(Int.self,          forKey: .number)
        type            = try container.decode(SeatType.self,     forKey: .type)
        status          = try container.decode(SeatStatus.self,   forKey: .status)
        priceMultiplier = try container.decode(Double.self,       forKey: .priceMultiplier)
        coupleGroupId   = try container.decodeIfPresent(String.self, forKey: .coupleGroupId)
    }

    // Memberwise init cho Mock và tạo thủ công
    init(
        id: String,
        row: String,
        number: Int,
        type: SeatType,
        status: SeatStatus,
        priceMultiplier: Double,
        coupleGroupId: String? = nil
    ) {
        self.id             = id
        self.row            = row
        self.number         = number
        self.type           = type
        self.status         = status
        self.priceMultiplier = priceMultiplier
        self.coupleGroupId  = coupleGroupId
    }
}

// MARK: - SeatMap

struct SeatMap: Equatable, Codable {
    let showtimeId: String
    let rows: [String]
    let seats: [Seat]
    let screenLabel: String

    func seats(inRow row: String) -> [Seat] {
        seats.filter { $0.row == row }.sorted { $0.number < $1.number }
    }

    var availableCount: Int {
        seats.filter { $0.status == .available }.count
    }

    var mySeats: [Seat] {
        seats.filter { $0.status == .mine }
    }
}

// MARK: - Mock Data

extension SeatMap {
    /// Bản đồ ghế mẫu:
    /// - Hàng A–B: VIP
    /// - Hàng C–G: Standard
    /// - Hàng H: Couple (H1-H2, H3-H4, H5-H6, H7-H8 là các cặp cố định)
    static func mock(showtimeId: String) -> SeatMap {
        let rows = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let seatsPerRow = 12
        var seats: [Seat] = []

        // Hàng couple: cặp cố định theo số chẵn/lẻ liền nhau
        // H1+H2 → group "H-1", H3+H4 → group "H-2", ...
        let coupleRow = "H"

        for (rowIndex, row) in rows.enumerated() {
            for number in 1...seatsPerRow {

                // --- Xác định loại ghế ---
                let seatType: Seat.SeatType
                let coupleGroupId: String?

                if row == coupleRow {
                    seatType = .couple
                    // Ghép cặp: 1-2, 3-4, 5-6, 7-8, 9-10, 11-12
                    let groupIndex = (number + 1) / 2   // 1→1, 2→1, 3→2, 4→2 ...
                    coupleGroupId = "\(row)-couple-\(groupIndex)"
                } else if rowIndex <= 1 {
                    seatType = .vip
                    coupleGroupId = nil
                } else {
                    seatType = .standard
                    coupleGroupId = nil
                }

                // --- Giả lập trạng thái ---
                let status: Seat.SeatStatus
                let randomVal = (rowIndex * seatsPerRow + number) % 7
                switch randomVal {
                case 0:    status = .booked
                case 1:    status = .held
                default:   status = .available
                }

                seats.append(Seat(
                    id: "\(row)\(number)",
                    row: row,
                    number: number,
                    type: seatType,
                    status: status,
                    priceMultiplier: seatType.priceMultiplier,
                    coupleGroupId: coupleGroupId
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
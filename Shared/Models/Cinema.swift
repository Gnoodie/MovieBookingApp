import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

// MARK: - Cinema

/// Entity đại diện cho một rạp chiếu phim
struct Cinema: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let name: String                // "CGV Vincom Center"
    let brand: Brand                // CGV, Lotte, BHD...
    let address: String             // Địa chỉ đầy đủ
    let city: String                // "Hà Nội", "TP.HCM"
    let district: String            // "Quận 1", "Đống Đa"
    let latitude: Double
    let longitude: Double
    let phoneNumber: String?
    let halls: [Hall]
    let amenities: [Amenity]        // Các tiện ích: parking, food court...

    // MARK: - Computed Properties

    /// Tọa độ để dùng với MapKit
#if canImport(CoreLocation)
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
#endif

    /// Tổng số phòng chiếu
    var totalHalls: Int { halls.count }

    /// Tổng số ghế toàn rạp
    var totalSeats: Int { halls.reduce(0) { $0 + $1.totalSeats } }

    // MARK: - Nested Types

    enum Brand: String, Codable, CaseIterable {
        case cgv = "CGV"
        case lotte = "Lotte Cinema"
        case bhd = "BHD Star"
        case galaxy = "Galaxy Cinema"
        case dcine = "Dcine"
        case other = "Other"

        var logoName: String { "logo_\(rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))" }
    }

    enum Amenity: String, Codable, CaseIterable {
        case parking = "Bãi đỗ xe"
        case foodCourt = "Khu ẩm thực"
        case atm = "ATM"
        case wheelchairAccess = "Tiếp cận xe lăn"
        case vipLounge = "Phòng chờ VIP"
    }

    // MARK: - Hall

    /// Phòng chiếu trong rạp
    struct Hall: Identifiable, Equatable, Hashable, Codable {
        let id: String
        let name: String            // "Phòng 1", "IMAX Hall", "Premium 4DX"
        let type: HallType
        let totalSeats: Int
        let rowCount: Int           // Số hàng ghế
        let seatsPerRow: Int        // Số ghế mỗi hàng (tối đa)

        enum HallType: String, Codable, CaseIterable {
            case standard = "Standard"
            case imax = "IMAX"
            case fourDX = "4DX"
            case dolby = "Dolby Atmos"
            case premium = "Premium"
            case screenX = "ScreenX"

            /// Nhãn hiển thị ngắn gọn trên badge
            var badge: String {
                switch self {
                case .standard: return "STD"
                case .imax:     return "IMAX"
                case .fourDX:   return "4DX"
                case .dolby:    return "DOLBY"
                case .premium:  return "PREM"
                case .screenX:  return "SCX"
                }
            }

            /// Giá nhân thêm so với vé thường
            var priceMultiplier: Double {
                switch self {
                case .standard: return 1.0
                case .premium:  return 1.3
                case .dolby:    return 1.5
                case .fourDX:   return 1.8
                case .imax:     return 2.0
                case .screenX:  return 2.2
                }
            }
        }
    }
}

// MARK: - Mock Data

extension Cinema {
    static let mocks: [Cinema] = [
        Cinema(
            id: "cinema-001",
            name: "CGV Vincom Center Bà Triệu",
            brand: .cgv,
            address: "191 Bà Triệu, Hai Bà Trưng",
            city: "Hà Nội",
            district: "Hai Bà Trưng",
            latitude: 21.0073,
            longitude: 105.8512,
            phoneNumber: "1900 6017",
            halls: [
                Hall(id: "hall-001", name: "Phòng 1 - IMAX",
                     type: .imax, totalSeats: 200, rowCount: 10, seatsPerRow: 20),
                Hall(id: "hall-002", name: "Phòng 2 - Standard",
                     type: .standard, totalSeats: 120, rowCount: 8, seatsPerRow: 15),
                Hall(id: "hall-003", name: "Phòng 3 - 4DX",
                     type: .fourDX, totalSeats: 80, rowCount: 8, seatsPerRow: 10),
            ],
            amenities: [.parking, .foodCourt, .atm]
        ),
        Cinema(
            id: "cinema-002",
            name: "Lotte Cinema Landmark 81",
            brand: .lotte,
            address: "772A Điện Biên Phủ, Bình Thạnh",
            city: "TP.HCM",
            district: "Bình Thạnh",
            latitude: 10.7956,
            longitude: 106.7218,
            phoneNumber: "1900 6159",
            halls: [
                Hall(id: "hall-004", name: "Phòng 1 - Dolby Atmos",
                     type: .dolby, totalSeats: 150, rowCount: 10, seatsPerRow: 15),
                Hall(id: "hall-005", name: "Phòng 2 - Standard",
                     type: .standard, totalSeats: 100, rowCount: 8, seatsPerRow: 13),
            ],
            amenities: [.parking, .foodCourt, .vipLounge, .wheelchairAccess]
        ),
    ]
}

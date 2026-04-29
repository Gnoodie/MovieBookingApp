import Foundation

// MARK: - Showtime

/// Entity đại diện cho một suất chiếu cụ thể
struct Showtime: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let movieId: String
    let cinemaId: String
    let hallId: String
    let startTime: Date
    let endTime: Date
    let language: Language
    let subtitleLanguage: Language?
    let format: Format
    let basePrice: Decimal          // Giá vé cơ bản (ghế thường, không phụ thu)
    let availableSeats: Int         // Số ghế còn trống (cập nhật real-time qua SSE)
    let totalSeats: Int

    // MARK: - Computed Properties

    /// Thời lượng phim tính từ startTime đến endTime
    var duration: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Phần trăm ghế đã đặt (dùng cho indicator)
    var occupancyRate: Double {
        guard totalSeats > 0 else { return 0 }
        return Double(totalSeats - availableSeats) / Double(totalSeats)
    }

    /// Trạng thái suất chiếu theo số ghế còn lại
    var availability: Availability {
        let remaining = availableSeats
        if remaining == 0 { return .soldOut }
        if remaining <= 10 { return .almostFull }
        return .available
    }

    // MARK: - Nested Types

    enum Language: String, Codable, CaseIterable {
        case vietnamese = "VI"
        case english = "EN"
        case korean = "KO"
        case japanese = "JA"
        case chinese = "ZH"

        var displayName: String {
            switch self {
            case .vietnamese: return "Tiếng Việt"
            case .english:    return "English"
            case .korean:     return "한국어"
            case .japanese:   return "日本語"
            case .chinese:    return "中文"
            }
        }

        var flagEmoji: String {
            switch self {
            case .vietnamese: return "🇻🇳"
            case .english:    return "🇺🇸"
            case .korean:     return "🇰🇷"
            case .japanese:   return "🇯🇵"
            case .chinese:    return "🇨🇳"
            }
        }
    }

    enum Format: String, Codable, CaseIterable {
        case twoD = "2D"
        case threeD = "3D"
        case imax = "IMAX"
        case fourDX = "4DX"
        case dolby = "Dolby"
        case screenX = "ScreenX"

        /// Hiển thị badge trên UI
        var badge: String { rawValue }

        /// Phụ thu so với giá cơ bản
        var surcharge: Decimal {
            switch self {
            case .twoD:    return 0
            case .threeD:  return 20_000
            case .dolby:   return 30_000
            case .fourDX:  return 50_000
            case .imax:    return 60_000
            case .screenX: return 70_000
            }
        }
    }

    enum Availability {
        case available      // Nhiều ghế trống
        case almostFull     // Còn ≤ 10 ghế
        case soldOut        // Hết ghế

        var label: String {
            switch self {
            case .available:  return "Còn vé"
            case .almostFull: return "Sắp hết"
            case .soldOut:    return "Hết vé"
            }
        }
    }
}

// MARK: - Mock Data

extension Showtime {
    static func mocks(for movieId: String, cinemaId: String) -> [Showtime] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            calendar.date(byAdding: .day, value: dayOffset, to: today)
                .flatMap { calendar.date(bySettingHour: hour, minute: minute, second: 0, of: $0) }
                ?? Date()
        }

        return [
            Showtime(
                id: "show-001",
                movieId: movieId,
                cinemaId: cinemaId,
                hallId: "hall-001",
                startTime: makeDate(dayOffset: 0, hour: 10, minute: 0),
                endTime: makeDate(dayOffset: 0, hour: 12, minute: 28),
                language: .english,
                subtitleLanguage: .vietnamese,
                format: .imax,
                basePrice: 150_000,
                availableSeats: 45,
                totalSeats: 200
            ),
            Showtime(
                id: "show-002",
                movieId: movieId,
                cinemaId: cinemaId,
                hallId: "hall-002",
                startTime: makeDate(dayOffset: 0, hour: 14, minute: 30),
                endTime: makeDate(dayOffset: 0, hour: 16, minute: 58),
                language: .vietnamese,
                subtitleLanguage: nil,
                format: .twoD,
                basePrice: 90_000,
                availableSeats: 8,
                totalSeats: 120
            ),
            Showtime(
                id: "show-003",
                movieId: movieId,
                cinemaId: cinemaId,
                hallId: "hall-003",
                startTime: makeDate(dayOffset: 0, hour: 19, minute: 45),
                endTime: makeDate(dayOffset: 0, hour: 22, minute: 13),
                language: .english,
                subtitleLanguage: .vietnamese,
                format: .fourDX,
                basePrice: 150_000,
                availableSeats: 0,
                totalSeats: 80
            ),
            Showtime(
                id: "show-004",
                movieId: movieId,
                cinemaId: cinemaId,
                hallId: "hall-001",
                startTime: makeDate(dayOffset: 1, hour: 9, minute: 15),
                endTime: makeDate(dayOffset: 1, hour: 11, minute: 43),
                language: .english,
                subtitleLanguage: .vietnamese,
                format: .imax,
                basePrice: 150_000,
                availableSeats: 180,
                totalSeats: 200
            ),
        ]
    }
}

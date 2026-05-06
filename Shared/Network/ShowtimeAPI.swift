import Foundation

// MARK: - Showtime API Endpoints

/// Định nghĩa các endpoint liên quan đến Showtimes (suất chiếu)
enum ShowtimeAPI {
    case list(movieId: String, date: String)            // date: "yyyy-MM-dd"
    case detail(id: String)
    case byCinema(cinemaId: String, date: String)
    case seatStream(showtimeId: String)                 // SSE endpoint — Sprint 3
}

extension ShowtimeAPI: APIEndpoint {
    var baseURL: String { "" }   // Firestore SDK — không dùng REST

    var path: String {
        switch self {
        case .list:                         return "/showtimes"
        case .detail(let id):               return "/showtimes/\(id)"
        case .byCinema:                     return "/showtimes"
        case .seatStream(let id):           return "/showtimes/\(id)/seat-stream"
        }
    }

    var method: String { "GET" }
    var headers: [String: String]? { nil }
    var body: Data? { nil }

    var queryString: String? {
        switch self {
        case .list(let movieId, let date):
            return "movieId=\(movieId)&date=\(date)"
        case .byCinema(let cinemaId, let date):
            return "cinemaId=\(cinemaId)&date=\(date)"
        default:
            return nil
        }
    }
}

// MARK: - Date Formatter Helper

extension ShowtimeAPI {
    /// Format Date thành "yyyy-MM-dd" để dùng với API
    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

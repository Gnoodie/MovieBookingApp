import Foundation

// MARK: - Cinema API Endpoints

/// Định nghĩa các endpoint liên quan đến Cinemas (rạp chiếu phim)
enum CinemaAPI {
    case list
    case nearby(lat: Double, lon: Double, radiusKm: Double)
    case detail(id: String)
}

extension CinemaAPI: APIEndpoint {
    var baseURL: String { "" }   // Firestore SDK — không dùng REST

    var path: String {
        switch self {
        case .list:             return "/cinemas"
        case .nearby:           return "/cinemas/nearby"
        case .detail(let id):   return "/cinemas/\(id)"
        }
    }

    var method: String { "GET" }
    var headers: [String: String]? { nil }
    var body: Data? { nil }

    var queryString: String? {
        switch self {
        case .nearby(let lat, let lon, let radius):
            return "lat=\(lat)&lon=\(lon)&radius=\(radius)"
        default:
            return nil
        }
    }
}

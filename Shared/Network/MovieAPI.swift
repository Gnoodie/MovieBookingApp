import Foundation

// MARK: - Movie API Endpoints

/// Định nghĩa các endpoint liên quan đến Movies
/// Conform APIEndpoint protocol (baseURL + path + method String + headers + body)
enum MovieAPI {
    case trending
    case nowPlaying
    case comingSoon
    case detail(id: String)
    case search(query: String, page: Int)
    case byGenre(genre: String)
}

extension MovieAPI: APIEndpoint {
    var baseURL: String { "" }   // Không dùng REST — Firestore SDK gọi trực tiếp

    var path: String {
        switch self {
        case .trending:             return "/movies/trending"
        case .nowPlaying:           return "/movies/now-playing"
        case .comingSoon:           return "/movies/coming-soon"
        case .detail(let id):       return "/movies/\(id)"
        case .search:               return "/movies/search"
        case .byGenre:              return "/movies"
        }
    }

    var method: String { "GET" }
    var headers: [String: String]? { nil }
    var body: Data? { nil }

    // MARK: - Query String Helpers (cho REST fallback)

    var queryString: String? {
        switch self {
        case .search(let query, let page):
            return "q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&page=\(page)"
        case .byGenre(let genre):
            return "genre=\(genre)"
        default:
            return nil
        }
    }
}

import Foundation

/// Các lỗi có thể xảy ra trong quá trình kết nối mạng
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(statusCode: Int)
    case decodingError
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL không hợp lệ."
        case .invalidResponse: return "Máy chủ trả về dữ liệu không hợp lệ."
        case .unauthorized: return "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        case .serverError(let code): return "Lỗi máy chủ (\(code)). Vui lòng thử lại sau."
        case .decodingError: return "Lỗi phân tích dữ liệu từ máy chủ."
        case .unknown: return "Đã xảy ra lỗi không xác định."
        }
    }
}

/// Giao thức cấu hình Endpoint (Ví dụ: /movies, /booking)
public protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

/// Trình xử lý mạng trung tâm sử dụng async/await (iOS 15+)
public final class NetworkClient {
    public static let shared = NetworkClient()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // Timeout sau 30 giây
        self.session = URLSession(configuration: config)
    }
    
    /// Gọi API và tự động phân tích (Decode) cục dữ liệu trả về theo Model T
    /// - Parameter endpoint: Cấu hình của API cần gọi
    /// - Returns: Dữ liệu đã được map vào Object Swift
    public func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body
        
        // Tự động đính kèm Token bảo mật nếu có trong Keychain
        if let token = KeychainWrapper.shared.get(forKey: "access_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Thực thi gọi mạng async
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Thành công
            do {
                let decoder = JSONDecoder()
                // Cấu hình tuỳ chọn Decoder ở đây nếu Backend trả về dạng SnakeCase
                // decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        case 401:
            // Hết hạn Token
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

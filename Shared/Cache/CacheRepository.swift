import Foundation

/// Repository quản lý bộ đệm nội bộ (Cache) cho phim và vé.
/// Chiến lược: Cache-First — hiển thị dữ liệu cũ từ bộ nhớ trước, fetch API ngầm cập nhật sau.
public final class CacheRepository {
    
    public static let shared = CacheRepository()
    
    /// Key lưu trữ trong UserDefaults (dùng cho dữ liệu nhẹ, không nhạy cảm)
    private let moviesKey = "cached_movies"
    private let ticketsKey = "cached_tickets"
    private let cacheTimestampKey = "cache_timestamp"
    
    /// Thời gian hết hạn cache (TTL): 30 phút
    private let cacheTTL: TimeInterval = 30 * 60
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - Movies Cache
    
    /// Lưu danh sách phim vào bộ đệm nội bộ
    public func saveMovies(_ movies: [Movie]) {
        do {
            let data = try encoder.encode(movies)
            defaults.set(data, forKey: moviesKey)
            defaults.set(Date().timeIntervalSince1970, forKey: "\(moviesKey)_timestamp")
            print("💾 Đã lưu \(movies.count) phim vào Cache")
        } catch {
            print("❌ Lỗi lưu phim vào Cache: \(error)")
        }
    }
    
    /// Lấy danh sách phim từ bộ đệm (nếu chưa hết hạn)
    public func loadMovies() -> [Movie]? {
        guard let data = defaults.data(forKey: moviesKey) else { return nil }
        
        // Kiểm tra TTL
        let timestamp = defaults.double(forKey: "\(moviesKey)_timestamp")
        if Date().timeIntervalSince1970 - timestamp > cacheTTL {
            print("⏰ Cache phim đã hết hạn")
            return nil // Cache quá cũ
        }
        
        do {
            let movies = try decoder.decode([Movie].self, from: data)
            print("📂 Đã đọc \(movies.count) phim từ Cache")
            return movies
        } catch {
            print("❌ Lỗi đọc phim từ Cache: \(error)")
            return nil
        }
    }
    
    // MARK: - Tickets Cache (Dùng cho truy cập Offline)
    
    /// Lưu danh sách vé đã mua vào bộ đệm để xem offline (QR không cần mạng)
    public func saveTickets(_ tickets: [Ticket]) {
        do {
            let data = try encoder.encode(tickets)
            defaults.set(data, forKey: ticketsKey)
            print("💾 Đã lưu \(tickets.count) vé vào Cache")
        } catch {
            print("❌ Lỗi lưu vé vào Cache: \(error)")
        }
    }
    
    /// Lấy danh sách vé từ bộ đệm (vé không hết hạn cache — luôn cần xem offline)
    public func loadTickets() -> [Ticket]? {
        guard let data = defaults.data(forKey: ticketsKey) else { return nil }
        
        do {
            let tickets = try decoder.decode([Ticket].self, from: data)
            print("📂 Đã đọc \(tickets.count) vé từ Cache")
            return tickets
        } catch {
            print("❌ Lỗi đọc vé từ Cache: \(error)")
            return nil
        }
    }
    
    // MARK: - Xoá Cache
    
    /// Xoá toàn bộ bộ đệm (dùng khi Đăng xuất)
    public func clearAll() {
        defaults.removeObject(forKey: moviesKey)
        defaults.removeObject(forKey: ticketsKey)
        defaults.removeObject(forKey: "\(moviesKey)_timestamp")
        print("🗑️ Đã xoá toàn bộ Cache")
    }
}

import Foundation
import UIKit

// MARK: - ImageCacheService

/// Actor-based, thread-safe image cache với memory + disk tầng.
/// Sử dụng NSCache cho memory, FileManager cho disk.
actor ImageCacheService {

    // MARK: Singleton

    static let shared = ImageCacheService()

    // MARK: Private State

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheDirectory: URL
    private let fileManager = FileManager.default

    // MARK: Init

    private init() {
        memoryCache.countLimit = 150       // Tối đa 150 ảnh trong RAM
        memoryCache.totalCostLimit = 1024 * 1024 * 80   // 80 MB

        // Thư mục cache trên disk
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheDirectory,
                                         withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Lấy ảnh từ cache hoặc tải từ mạng
    func image(for url: URL) async throws -> UIImage {
        let key = cacheKey(for: url)

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // 2. Disk cache
        let diskURL = diskCacheDirectory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: diskURL),
           let image = UIImage(data: data) {
            // Warm up memory cache
            memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
            return image
        }

        // 3. Network fetch
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data)
        else {
            throw ImageCacheError.invalidResponse
        }

        // Lưu vào cả hai tầng
        memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
        try? data.write(to: diskURL)

        return image
    }

    /// Xóa cache ảnh của một URL cụ thể
    func remove(url: URL) {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key as NSString)
        let diskURL = diskCacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: diskURL)
    }

    /// Xóa toàn bộ disk cache (không xóa memory vì actor-safe)
    func clearDiskCache() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: nil
        )
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }

    // MARK: - Private Helpers

    private func cacheKey(for url: URL) -> String {
        // Dùng SHA-256 đơn giản thay bằng hash URL để tạo filename an toàn
        let urlString = url.absoluteString
        return urlString.hash.description + ".jpg"
    }
}

// MARK: - Errors

enum ImageCacheError: LocalizedError {
    case invalidResponse
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Server trả về response không hợp lệ."
        case .invalidData: return "Dữ liệu ảnh bị lỗi."
        }
    }
}

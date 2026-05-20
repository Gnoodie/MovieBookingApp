import Foundation

/// Phiên bản nội bộ của SharedUserSession dùng trong AppIntentsExtension.
/// Logic giống hệt Shared/Security/SharedUserSession.swift — chia sẻ file tạm trên cùng Mac Host.
struct SharedUserSession {
    private static let appGroupId = "group.com.gnoodie.MovieBookingApp"
    private static let userUidKey = "current_user_uid"

    // Đường dẫn file chia sẻ trên Simulator Mac Host
    private static var simulatorSharedFileURL: URL? {
        #if targetEnvironment(simulator)
        return URL(fileURLWithPath: "/tmp/movie_booking_user_uid.txt")
        #else
        return nil
        #endif
    }

    /// Lưu User ID vào các kênh chia sẻ
    static func saveUserUid(_ uid: String) {
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.set(uid, forKey: userUidKey)
            sharedDefaults.synchronize()
        }
        if let fileURL = simulatorSharedFileURL {
            try? uid.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Đọc User ID từ các kênh chia sẻ
    static func getUserUid() -> String? {
        // 1. Đọc từ App Group UserDefaults (Device thật)
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let uid = sharedDefaults.string(forKey: userUidKey),
           !uid.isEmpty {
            print("👤 [SiriExtension] Retrieved UID from App Group: \(uid)")
            return uid
        }

        // 2. Đọc từ file tạm chia sẻ trên Mac Host (Simulator)
        if let fileURL = simulatorSharedFileURL,
           let uid = try? String(contentsOf: fileURL, encoding: .utf8)
               .trimmingCharacters(in: .whitespacesAndNewlines),
           !uid.isEmpty {
            print("👤 [SiriExtension] Retrieved UID from Simulator Temp File: \(uid)")
            return uid
        }

        print("👤 [SiriExtension] No shared UID found — falling back to siri-guest")
        return nil
    }

    /// Xoá User ID (dùng khi đăng xuất)
    static func clearUserUid() {
        UserDefaults(suiteName: appGroupId)?.removeObject(forKey: userUidKey)
        if let fileURL = simulatorSharedFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

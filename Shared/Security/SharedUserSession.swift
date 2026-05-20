import Foundation

/// Hỗ trợ chia sẻ thông tin User Session giữa Main App và Siri AppIntentsExtension.
/// Hỗ trợ cả cơ chế chính thức (App Groups) và cơ chế giả lập tiện lợi (Mac Host Shared File).
public struct SharedUserSession {
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
    public static func saveUserUid(_ uid: String) {
        // 1. Lưu vào App Group UserDefaults (Dành cho Device thực & Simulator cấu hình chuẩn)
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.set(uid, forKey: userUidKey)
            sharedDefaults.synchronize()
            print("👤 [SharedUserSession] Saved UID to App Group: \(uid)")
        }
        
        // 2. Lưu vào file tạm dùng chung trên Mac Host (Dành cho test nhanh trên Simulator)
        if let fileURL = simulatorSharedFileURL {
            do {
                try uid.write(to: fileURL, atomically: true, encoding: .utf8)
                print("👤 [SharedUserSession] Saved UID to Simulator Temp File: \(uid)")
            } catch {
                print("⚠️ [SharedUserSession] Failed to write to Simulator Temp File: \(error)")
            }
        }
    }
    
    /// Đọc User ID từ các kênh chia sẻ
    public static func getUserUid() -> String? {
        // 1. Đọc từ App Group UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let uid = sharedDefaults.string(forKey: userUidKey),
           !uid.isEmpty {
            print("👤 [SharedUserSession] Retrieved UID from App Group: \(uid)")
            return uid
        }
        
        // 2. Đọc từ file tạm dùng chung trên Mac Host (Dành cho Simulator)
        if let fileURL = simulatorSharedFileURL {
            if let uid = try? String(contentsOf: fileURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
               !uid.isEmpty {
                print("👤 [SharedUserSession] Retrieved UID from Simulator Temp File: \(uid)")
                return uid
            }
        }
        
        print("👤 [SharedUserSession] No shared UID found")
        return nil
    }
    
    /// Xoá User ID khỏi các kênh chia sẻ (khi đăng xuất)
    public static func clearUserUid() {
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.removeObject(forKey: userUidKey)
            sharedDefaults.synchronize()
            print("👤 [SharedUserSession] Cleared UID from App Group")
        }
        
        if let fileURL = simulatorSharedFileURL {
            try? FileManager.default.removeItem(at: fileURL)
            print("👤 [SharedUserSession] Cleared UID from Simulator Temp File")
        }
    }
}

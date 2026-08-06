import SwiftUI
import Combine
import os.log
import FirebaseAuth

/// Quản lý trạng thái tổng của toàn bộ ứng dụng (thay thế AppStore TCA)
public class AppViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var showLoginSheet: Bool = false
    @Published public var selectedTab: Tab = .home
    private static let logger = Logger(subsystem: "com.cinematicket", category: "AppLifecycle")
    
    public enum Tab: Hashable {
        case home, search, tickets, profile
    }
    
    public init() {
        // Ưu tiên kiểm tra phiên đăng nhập trực tiếp từ Firebase Auth
        if let currentUser = Auth.auth().currentUser {
            self.isAuthenticated = true
            KeychainWrapper.shared.save(currentUser.uid, forKey: "access_token")
            SharedUserSession.saveUserUid(currentUser.uid)
        } else if let token = KeychainWrapper.shared.get(forKey: "access_token"), !token.isEmpty {
            self.isAuthenticated = true
            SharedUserSession.saveUserUid(token)
        } else {
            self.isAuthenticated = false
        }
    }
    
    /// Đăng xuất: Xoá token, xoá cache, quay về màn hình Login
    @MainActor
    public func signOut() {
        // Gọi Firebase signOut trong Task vì FirebaseAuthManager là Actor
        Task {
            do {
                try await FirebaseAuthManager.shared.signOut()
            } catch {
                Self.logger.error("⚠️ Lỗi đăng xuất Firebase: \(error.localizedDescription)")
            }
        }
        
        // Xoá token khỏi Két sắt
        KeychainWrapper.shared.delete(forKey: "access_token")
        
        // Xoá UID khỏi kênh chia sẻ
        SharedUserSession.clearUserUid()
        
        // Xoá dữ liệu cache (UserDefaults)
        UserDefaults.standard.removeObject(forKey: "cached_movies")
        UserDefaults.standard.removeObject(forKey: "cached_tickets")
        UserDefaults.standard.removeObject(forKey: "cached_movies_timestamp")
        
        // Quay về màn hình đăng nhập với hiệu ứng mượt
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
        }
    }
}

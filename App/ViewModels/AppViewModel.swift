import SwiftUI
import Combine

/// Quản lý trạng thái tổng của toàn bộ ứng dụng (thay thế AppStore TCA)
public class AppViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var selectedTab: Tab = .home
    
    public enum Tab: Hashable {
        case home, search, tickets, profile
    }
    
    public init() {
        // Kiểm tra xem Két sắt Keychain đã có token chưa
        // Nếu có thì đổi trạng thái sang đã đăng nhập để bỏ qua màn Login
        if let _ = KeychainWrapper.shared.get(forKey: "access_token") {
            self.isAuthenticated = true
        }
    }
    
    /// Đăng xuất: Xoá token, xoá cache, quay về màn hình Login
    @MainActor
    public func signOut() {
        do {
            try FirebaseAuthManager.shared.signOut()
        } catch {
            print("⚠️ Lỗi đăng xuất Firebase: \(error)")
        }
        
        // Xoá token khỏi Két sắt
        KeychainWrapper.shared.delete(forKey: "access_token")
        
        // Xoá dữ liệu cache
        CacheRepository.shared.clearAll()
        
        // Quay về màn hình đăng nhập với hiệu ứng mượt
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
        }
    }
}

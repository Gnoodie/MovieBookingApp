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
}

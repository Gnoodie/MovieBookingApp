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
        // Có thể check Keychain xem người dùng đã đăng nhập trước đó chưa
        // Nếu có thì isAuthenticated = true
    }
}

import ComposableArchitecture

@Reducer
struct AppFeature {
    // MARK: - State
    // Tất cả biến quyết định UI ở đây
    @ObservableState
    struct State: Equatable {
        var isAuthenticated: Bool = false
        var selectedTab: Tab = .home
        
        // Child states (Sprint 1 sẽ phức tạp hơn)
        // var home: HomeFeature.State = .init()
    }
    
    // MARK: - Action
    // Tất cả sự kiện từ UI hoặc Effect gửi về đây
    enum Action {
        case appLaunched
        case tabSelected(Tab)
        case authStateChanged(Bool)
    }
    
    // MARK: - Body (Reducer)
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appLaunched:
                // Sẽ check Keychain xem có token không (Sprint 1)
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case let .authStateChanged(isAuth):
                state.isAuthenticated = isAuth
                return .none
            }
        }
    }
    
    // MARK: - Types
    enum Tab: Hashable {
        case home, search, tickets, profile
    }
}

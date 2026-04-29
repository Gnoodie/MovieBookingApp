import ComposableArchitecture
import Foundation

/// Tính năng Xác thực (Đăng nhập / Đăng ký) quản lý bằng TCA
@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var isLoading = false
        public var errorMessage: String? = nil
        
        public init() {}
    }
    
    public enum Action {
        case emailChanged(String)
        case passwordChanged(String)
        case loginButtonTapped
        case loginResponse(Result<String, Error>)
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(email):
                state.email = email
                state.errorMessage = nil
                return .none
                
            case let .passwordChanged(password):
                state.password = password
                state.errorMessage = nil
                return .none
                
            case .loginButtonTapped:
                guard !state.email.isEmpty, !state.password.isEmpty else {
                    state.errorMessage = "Vui lòng nhập Email và Mật khẩu"
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                
                let email = state.email
                let password = state.password
                
                return .run { send in
                    do {
                        // Gọi FirebaseAuthManager (an toàn vì đã có Mock fallback)
                        let uid = try await FirebaseAuthManager.shared.signIn(email: email, password: password)
                        await send(.loginResponse(.success(uid)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case let .loginResponse(.success(uid)):
                state.isLoading = false
                // TODO: Chuyển hướng sang màn hình Home (sẽ cấu hình ở AppStore)
                print("Đăng nhập thành công với UID: \(uid)")
                return .none
                
            case let .loginResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

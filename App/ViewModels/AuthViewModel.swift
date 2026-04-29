import SwiftUI
import Combine

/// Quản lý trạng thái và logic của giao diện Đăng nhập (thay thế AuthFeature TCA)
public class AuthViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String? = nil
    
    // Nơi lưu trữ AppViewModel để báo hiệu đăng nhập thành công
    private weak var appViewModel: AppViewModel?
    
    public init(appViewModel: AppViewModel? = nil) {
        self.appViewModel = appViewModel
    }
    
    @MainActor
    public func loginButtonTapped() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập Email và Mật khẩu"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let currentEmail = email
        let currentPassword = password
        
        Task {
            do {
                let uid = try await FirebaseAuthManager.shared.signIn(email: currentEmail, password: currentPassword)
                self.isLoading = false
                print("Đăng nhập thành công với UID: \(uid)")
                
                // Đổi trạng thái toàn App để chuyển vào màn hình Home
                self.appViewModel?.isAuthenticated = true
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

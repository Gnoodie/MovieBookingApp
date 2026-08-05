import SwiftUI
import Combine
import os.log

/// Quản lý trạng thái và logic của giao diện Đăng nhập / Đăng ký
public class AuthViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public var isLoginMode = true
    
    @Published public var isLoading = false
    @Published public var errorMessage: String? = nil
    
    private weak var appViewModel: AppViewModel?
    private static let logger = Logger(subsystem: "com.cinematicket", category: "Auth")
    
    public init(appViewModel: AppViewModel? = nil) {
        self.appViewModel = appViewModel
    }
    
    @MainActor
    public func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
        password = ""
        confirmPassword = ""
    }
    
    @MainActor
    public func authenticate() {
        // Validate cơ bản
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập Email và Mật khẩu"
            return
        }
        
        if !isLoginMode {
            guard password == confirmPassword else {
                errorMessage = "Mật khẩu xác nhận không khớp"
                return
            }
            guard password.count >= 6 else {
                errorMessage = "Mật khẩu phải có ít nhất 6 ký tự"
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        let currentEmail = email
        let currentPassword = password
        let isLogin = isLoginMode
        
        Task {
            do {
                let uid: String
                if isLogin {
                    uid = try await FirebaseAuthManager.shared.signIn(email: currentEmail, password: currentPassword)
                    Self.logger.info("Đăng nhập thành công với UID: \(uid)")
                } else {
                    uid = try await FirebaseAuthManager.shared.signUp(email: currentEmail, password: currentPassword)
                    Self.logger.info("Đăng ký thành công với UID: \(uid)")
                }
                
                // Lưu UID / Token vào Két sắt (Keychain) để ghi nhớ đăng nhập
                KeychainWrapper.shared.save(uid, forKey: "access_token")
                
                // Chia sẻ UID với Siri Extension
                SharedUserSession.saveUserUid(uid)
                
                self.isLoading = false
                
                // Đổi trạng thái toàn App để chuyển vào màn hình Home
                withAnimation {
                    self.appViewModel?.isAuthenticated = true
                    self.appViewModel?.showLoginSheet = false
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

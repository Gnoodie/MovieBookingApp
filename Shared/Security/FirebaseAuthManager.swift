import Foundation
import FirebaseAuth

/// Lớp bọc (Wrapper) các chức năng xác thực của Firebase.
/// Giúp ứng dụng không bị phụ thuộc trực tiếp vào Firebase SDK ở các tầng Giao diện (UI).
public actor FirebaseAuthManager {
    public static let shared = FirebaseAuthManager()
    
    private init() {}
    
    /// Kiểm tra xem người dùng hiện tại đã đăng nhập chưa
    public var currentUserUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Đăng nhập bằng Email và Mật khẩu
    public func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }
    
    /// Đăng ký tài khoản mới bằng Email và Mật khẩu
    public func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }
    
    /// Đăng xuất khỏi ứng dụng
    public func signOut() throws {
        try Auth.auth().signOut()
    }

    /// Xóa tài khoản Firebase Auth vĩnh viễn (theo yêu cầu Apple 5.1.1)
    public func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }
}

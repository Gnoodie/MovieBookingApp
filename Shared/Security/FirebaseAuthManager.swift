import Foundation

#if canImport(FirebaseAuth)
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
}
#else
/// Mock Manager cho máy Windows/Linux không cài được Firebase SDK
public actor FirebaseAuthManager {
    public static let shared = FirebaseAuthManager()
    private init() {}
    
    public var currentUserUID: String? { return nil }
    
    public func signIn(email: String, password: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if email.isEmpty || password.isEmpty {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Vui lòng nhập đầy đủ thông tin"])
        }
        return "mock_user_123"
    }
    
    public func signUp(email: String, password: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "mock_user_123"
    }
    
    public func signOut() throws {}
}
#endif

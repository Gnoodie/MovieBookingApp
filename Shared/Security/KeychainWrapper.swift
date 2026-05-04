import Foundation
import Security

/// Một lớp Wrapper hỗ trợ lưu trữ thông tin nhạy cảm (Token, Password) vào Apple Keychain.
/// Dữ liệu lưu trong Keychain được mã hoá ở cấp độ OS và không bị xoá ngay cả khi gỡ cài đặt App.
public final class KeychainWrapper {
    
    public static let shared = KeychainWrapper()
    
    private init() {}
    
    /// Lưu trữ một chuỗi String (như JWT Token) vào Keychain một cách an toàn
    /// - Parameters:
    ///   - value: Giá trị cần lưu (String)
    ///   - key: Khoá (Key) để định danh dữ liệu
    /// - Returns: `true` nếu lưu thành công
    @discardableResult
    public func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Xoá giá trị cũ (nếu có) trước khi thêm mới để tránh lỗi trùng lặp
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Lấy chuỗi String từ Keychain
    /// - Parameter key: Khoá (Key) đã sử dụng khi lưu
    /// - Returns: Giá trị String (nếu tồn tại)
    public func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    /// Xoá dữ liệu khỏi Keychain (Thường dùng khi Đăng xuất)
    /// - Parameter key: Khoá (Key) cần xoá
    @discardableResult
    public func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Xoá toàn bộ dữ liệu do App tạo ra trong Keychain
    public func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        SecItemDelete(query as CFDictionary)
    }
}

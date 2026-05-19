import Foundation

// MARK: - UserProfile

/// Entity đại diện cho hồ sơ người dùng, lưu tại Firestore: users/{uid}
struct UserProfile: Identifiable, Codable, Equatable {
    let id: String                      // = Firebase UID
    var displayName: String
    var email: String
    var phoneNumber: String?
    var avatarURL: URL?
    var joinedAt: Date
    var totalBookings: Int              // Cập nhật sau mỗi lần đặt vé thành công
    var favoriteMovieIds: [String]      // Danh sách movieId yêu thích

    // MARK: - Computed

    /// Chữ cái đầu để hiển thị Avatar fallback
    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts.first!.prefix(1) + parts.last!.prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    /// Ngày tham gia dạng "Tháng 5, 2026"
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM, yyyy"
        return formatter.string(from: joinedAt)
    }
}

// MARK: - Mock

extension UserProfile {
    static let mock = UserProfile(
        id: "mock-user-001",
        displayName: "Nguyễn Văn An",
        email: "nguyenvanan@example.com",
        phoneNumber: "0901234567",
        avatarURL: nil,
        joinedAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        totalBookings: 7,
        favoriteMovieIds: ["movie-001", "movie-003"]
    )
}

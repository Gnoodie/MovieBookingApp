import Foundation
import FirebaseFirestore

// MARK: - UserRepositoryProtocol

protocol UserRepositoryProtocol {
    func fetchProfile(userId: String) async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws
    func incrementBookingCount(userId: String) async throws
    func toggleFavorite(userId: String, movieId: String) async throws -> Bool
    func deleteProfile(userId: String) async throws
}

// MARK: - FirestoreUserRepository

final class FirestoreUserRepository: UserRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "users"

    // MARK: - Fetch

    func fetchProfile(userId: String) async throws -> UserProfile {
        let doc = try await db.collection(collection).document(userId).getDocument()

        if doc.exists, let data = doc.data() {
            return try mapToProfile(data: data, id: userId)
        }

        // Nếu document chưa tồn tại → tạo profile mặc định từ Auth info
        let defaultProfile = UserProfile(
            id: userId,
            displayName: "Khách hàng",
            email: "",
            phoneNumber: nil,
            avatarURL: nil,
            joinedAt: Date(),
            totalBookings: 0,
            favoriteMovieIds: []
        )
        // Tạo document mới
        try await db.collection(collection).document(userId).setData(mapToData(defaultProfile))
        return defaultProfile
    }

    // MARK: - Update

    func updateProfile(_ profile: UserProfile) async throws {
        let data: [String: Any] = [
            "displayName": profile.displayName,
            "phoneNumber": profile.phoneNumber as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection(collection).document(profile.id).updateData(data)
    }

    // MARK: - Booking count

    func incrementBookingCount(userId: String) async throws {
        try await db.collection(collection).document(userId).updateData([
            "totalBookings": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Favorites

    func toggleFavorite(userId: String, movieId: String) async throws -> Bool {
        let ref = db.collection(collection).document(userId)
        let doc = try await ref.getDocument()
        let favorites = doc.data()?["favoriteMovieIds"] as? [String] ?? []
        let isFav = favorites.contains(movieId)

        if isFav {
            try await ref.updateData(["favoriteMovieIds": FieldValue.arrayRemove([movieId])])
        } else {
            try await ref.updateData(["favoriteMovieIds": FieldValue.arrayUnion([movieId])])
        }
        return !isFav
    }

    // MARK: - Delete Profile

    func deleteProfile(userId: String) async throws {
        try await db.collection(collection).document(userId).delete()
    }

    // MARK: - Mapping

    private func mapToProfile(data: [String: Any], id: String) throws -> UserProfile {
        let displayName  = data["displayName"]  as? String ?? "Người dùng"
        let email        = data["email"]        as? String ?? ""
        let phoneNumber  = data["phoneNumber"]  as? String
        let totalBookings = data["totalBookings"] as? Int ?? 0
        let favorites    = data["favoriteMovieIds"] as? [String] ?? []

        let joinedAt: Date
        if let ts = data["joinedAt"] as? Timestamp {
            joinedAt = ts.dateValue()
        } else {
            joinedAt = Date()
        }

        let avatarURL: URL?
        if let urlStr = data["avatarURL"] as? String {
            avatarURL = URL(string: urlStr)
        } else {
            avatarURL = nil
        }

        return UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            phoneNumber: phoneNumber,
            avatarURL: avatarURL,
            joinedAt: joinedAt,
            totalBookings: totalBookings,
            favoriteMovieIds: favorites
        )
    }

    private func mapToData(_ profile: UserProfile) -> [String: Any] {
        var data: [String: Any] = [
            "displayName":     profile.displayName,
            "email":           profile.email,
            "totalBookings":   profile.totalBookings,
            "favoriteMovieIds": profile.favoriteMovieIds,
            "joinedAt":        Timestamp(date: profile.joinedAt)
        ]
        if let phone = profile.phoneNumber { data["phoneNumber"] = phone }
        if let url = profile.avatarURL    { data["avatarURL"]   = url.absoluteString }
        return data
    }
}

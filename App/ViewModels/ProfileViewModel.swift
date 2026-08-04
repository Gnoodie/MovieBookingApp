import Foundation
import os.log

// MARK: - ProfileViewModel

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published State

    @Published var profile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    /// Controls EditProfileSheet
    @Published var isEditingProfile: Bool = false

    /// Controls sign-out confirmation alert
    @Published var showSignOutAlert: Bool = false

    /// Controls delete account confirmation alert
    @Published var showDeleteAccountAlert: Bool = false

    // MARK: - Dependencies

    private let userRepository: UserRepositoryProtocol
    weak var appViewModel: AppViewModel?

    private static let logger = Logger(subsystem: "com.cinematicket", category: "Profile")

    // MARK: - Init

    init(
        userRepository: UserRepositoryProtocol = FirestoreUserRepository(),
        appViewModel: AppViewModel? = nil
    ) {
        self.userRepository = userRepository
        self.appViewModel = appViewModel
    }

    // MARK: - Lifecycle

    func onAppear() {
        guard profile == nil else { return }
        Task { await loadProfile() }
    }

    // MARK: - Load

    func loadProfile() async {
        guard let uid = await currentUID() else {
            errorMessage = "Vui lòng đăng nhập lại."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            profile = try await userRepository.fetchProfile(userId: uid)
            Self.logger.info("Profile loaded for user: \(uid)")
        } catch {
            errorMessage = "Không thể tải hồ sơ: \(error.localizedDescription)"
            Self.logger.error("Failed to load profile: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Save

    func saveProfile(displayName: String, phoneNumber: String?) async {
        guard var updatedProfile = profile else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Tên không được để trống."
            return
        }

        updatedProfile.displayName = trimmedName
        updatedProfile.phoneNumber = phoneNumber?.isEmpty == false ? phoneNumber : nil

        isSaving = true
        errorMessage = nil

        do {
            try await userRepository.updateProfile(updatedProfile)
            profile = updatedProfile
            isEditingProfile = false
            successMessage = "Hồ sơ đã được cập nhật!"
            Self.logger.info("Profile updated successfully.")

            // Clear success message after 2s
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Lưu thất bại: \(error.localizedDescription)"
            Self.logger.error("Failed to save profile: \(error.localizedDescription)")
        }

        isSaving = false
    }

    // MARK: - Favorites

    func toggleFavorite(movieId: String) async {
        guard let uid = await currentUID() else { return }

        do {
            let isFav = try await userRepository.toggleFavorite(userId: uid, movieId: movieId)
            if isFav {
                profile?.favoriteMovieIds.append(movieId)
            } else {
                profile?.favoriteMovieIds.removeAll { $0 == movieId }
            }
        } catch {
            Self.logger.error("Toggle favorite failed: \(error.localizedDescription)")
        }
    }

    func isFavorite(movieId: String) -> Bool {
        profile?.favoriteMovieIds.contains(movieId) ?? false
    }

    // MARK: - Sign Out

    func confirmSignOut() {
        showSignOutAlert = true
    }

    func signOut() {
        appViewModel?.signOut()
    }

    // MARK: - Delete Account

    func confirmDeleteAccount() {
        showDeleteAccountAlert = true
    }

    func deleteAccount() {
        Task {
            guard let uid = await currentUID() else { return }
            do {
                // 1. Xóa dữ liệu Firestore của user
                try? await userRepository.deleteProfile(userId: uid)

                // 2. Xóa tài khoản Firebase Auth (bắt buộc theo Apple 5.1.1)
                try await FirebaseAuthManager.shared.deleteAccount()

                // 3. Đăng xuất khỏi app
                await MainActor.run {
                    appViewModel?.signOut()
                }
                Self.logger.info("Account deleted successfully for user: \(uid)")
            } catch {
                await MainActor.run {
                    errorMessage = "Xóa tài khoản thất bại: \(error.localizedDescription)"
                }
                Self.logger.error("Delete account failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func currentUID() async -> String? {
        await FirebaseAuthManager.shared.currentUserUID
    }
}

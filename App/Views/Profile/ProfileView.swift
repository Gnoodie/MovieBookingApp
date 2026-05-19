import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var appViewModel: AppViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    ProfileSkeletonView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header
                            ProfileHeaderSection(profile: viewModel.profile)
                                .padding(.bottom, 24)

                            // Stats
                            if let profile = viewModel.profile {
                                ProfileStatsSection(profile: profile)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            }

                            // Menu sections
                            VStack(spacing: 12) {
                                // Account section
                                ProfileMenuSection(title: "Tài khoản") {
                                    ProfileMenuRow(
                                        icon: "person.fill",
                                        iconColor: .accentTeal,
                                        title: "Chỉnh sửa hồ sơ"
                                    ) {
                                        viewModel.isEditingProfile = true
                                    }
                                    ProfileMenuRow(
                                        icon: "bell.fill",
                                        iconColor: .accentGold,
                                        title: "Thông báo"
                                    ) { }
                                    ProfileMenuRow(
                                        icon: "lock.fill",
                                        iconColor: Color(hex: "#FF9F0A"),
                                        title: "Bảo mật & Quyền riêng tư"
                                    ) { }
                                }

                                // App section
                                ProfileMenuSection(title: "Ứng dụng") {
                                    ProfileMenuRow(
                                        icon: "globe",
                                        iconColor: Color(hex: "#30D158"),
                                        title: "Ngôn ngữ",
                                        value: "Tiếng Việt"
                                    ) { }
                                    ProfileMenuRow(
                                        icon: "star.fill",
                                        iconColor: .accentGold,
                                        title: "Đánh giá ứng dụng",
                                        showChevron: true
                                    ) { }
                                    ProfileMenuRow(
                                        icon: "doc.text.fill",
                                        iconColor: .textSecondary,
                                        title: "Điều khoản sử dụng",
                                        showChevron: true
                                    ) { }
                                }

                                // Sign out
                                Button {
                                    viewModel.confirmSignOut()
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Đăng xuất")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.statusError)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.statusError.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(Color.statusError.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(14)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                                // Version
                                Text("Cinematicket v1.0.0 (Sprint 5)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textDisabled)
                                    .padding(.vertical, 20)
                            }
                        }
                    }
                    .refreshable { await viewModel.loadProfile() }
                }

                // Success toast
                if let msg = viewModel.successMessage {
                    ToastView(message: msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.appViewModel = appViewModel
            viewModel.onAppear()
        }
        // Edit Profile Sheet
        .sheet(isPresented: $viewModel.isEditingProfile) {
            EditProfileView(viewModel: viewModel)
        }
        // Sign Out Alert
        .alert("Đăng xuất?", isPresented: $viewModel.showSignOutAlert) {
            Button("Đăng xuất", role: .destructive) { viewModel.signOut() }
            Button("Huỷ", role: .cancel) { }
        } message: {
            Text("Bạn có chắc muốn đăng xuất khỏi Cinematicket không?")
        }
    }
}

// MARK: - Profile Header Section

private struct ProfileHeaderSection: View {
    let profile: UserProfile?

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color.backgroundPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentGold, Color(hex: "#F0C850")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    Text(profile?.initials ?? "?")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.black)
                }
                .shadow(color: Color.accentGold.opacity(0.5), radius: 16, y: 6)

                // Name
                Text(profile?.displayName ?? "Đang tải...")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                // Email
                Text(profile?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)

                // Join date
                if let profile {
                    Text("Thành viên từ \(profile.formattedJoinDate)")
                        .font(.system(size: 12))
                        .foregroundColor(.textDisabled)
                }
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Stats Section

private struct ProfileStatsSection: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(profile.totalBookings)",
                label: "Vé đã mua",
                icon: "ticket.fill",
                color: .accentGold
            )
            StatCard(
                value: "\(profile.favoriteMovieIds.count)",
                label: "Phim yêu thích",
                icon: "heart.fill",
                color: .statusError
            )
            StatCard(
                value: "⭐",
                label: "Thành viên",
                icon: "star.fill",
                color: .accentTeal
            )
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.backgroundSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

// MARK: - Menu Section

private struct ProfileMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textDisabled)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.backgroundSecondary)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Menu Row

private struct ProfileMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                // Optional value
                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textDisabled)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .background(Color.backgroundTertiary)
            .padding(.leading, 64)
    }
}

// MARK: - Skeleton Loading

private struct ProfileSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Avatar skeleton
            Circle()
                .fill(Color.backgroundSecondary)
                .frame(width: 88, height: 88)
                .padding(.top, 60)

            // Name skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.backgroundSecondary)
                .frame(width: 160, height: 22)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.backgroundSecondary)
                .frame(width: 200, height: 16)

            Spacer()
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Toast

private struct ToastView: View {
    let message: String

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.statusSuccess)
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .padding(.top, 56)

            Spacer()
        }
    }
}

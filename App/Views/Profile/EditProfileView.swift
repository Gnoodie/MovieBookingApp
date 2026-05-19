import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var phoneNumber: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Avatar display (read-only)
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentGold, Color(hex: "#F0C850")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Text(viewModel.profile?.initials ?? "?")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                        }
                        .shadow(color: Color.accentGold.opacity(0.4), radius: 12, y: 4)
                        .padding(.top, 8)

                        // Form fields
                        VStack(spacing: 16) {
                            EditField(
                                title: "Tên hiển thị",
                                placeholder: "Nhập tên của bạn",
                                text: $displayName,
                                icon: "person.fill"
                            )

                            EditField(
                                title: "Số điện thoại",
                                placeholder: "0901 234 567 (tùy chọn)",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad
                            )

                            // Email (read-only)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textDisabled)
                                        .frame(width: 20)

                                    Text(viewModel.profile?.email ?? "")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textDisabled)

                                    Spacer()

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textDisabled)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.backgroundSecondary.opacity(0.6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Error message
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.statusError)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.statusError)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Save Button
                        Button {
                            Task {
                                await viewModel.saveProfile(
                                    displayName: displayName,
                                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                                )
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Lưu thay đổi")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentGold, Color(hex: "#F0C850")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.accentGold.opacity(0.4), radius: 10, y: 4)
                        }
                        .disabled(viewModel.isSaving || displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(displayName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isSaving)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Chỉnh sửa hồ sơ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .onAppear {
            displayName = viewModel.profile?.displayName ?? ""
            phoneNumber = viewModel.profile?.phoneNumber ?? ""
        }
    }
}

// MARK: - EditField Component

private struct EditField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.accentGold)
                    .frame(width: 20)

                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textDisabled))
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.backgroundSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        text.isEmpty ? Color.backgroundTertiary : Color.accentGold.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        }
    }
}

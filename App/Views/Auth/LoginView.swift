import ComposableArchitecture
import SwiftUI

public struct LoginView: View {
    @Bindable var store: StoreOf<AuthFeature>
    
    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            // Nền đen phong cách điện ảnh
            Color.black.ignoresSafeArea()
            
            // Lớp nền trang trí thêm (nếu cần)
            LinearGradient(
                colors: [Color(hex: "#1C1C1E"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Tiêu đề
                VStack(spacing: 10) {
                    Text("Cinematicket")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#D4AF37")) // Gold accent
                    
                    Text("Đăng nhập để đặt vé")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Form đăng nhập
                VStack(spacing: 20) {
                    // Cần tạo GlassCardView từ Sprint 0 hoặc tự bọc
                    VStack(spacing: 15) {
                        TextField("Email", text: $store.email.sending(\.emailChanged))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        SecureField("Mật khẩu", text: $store.password.sending(\.passwordChanged))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color(hex: "#1C1C1E").opacity(0.8)) // Glassmorphism fake
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Nút đăng nhập
                    Button {
                        store.send(.loginButtonTapped)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#D4AF37"))
                            
                            if store.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("ĐĂNG NHẬP")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(height: 55)
                    }
                    .disabled(store.isLoading)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

// Hàm hỗ trợ mã màu Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

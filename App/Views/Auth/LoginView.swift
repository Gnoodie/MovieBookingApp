import SwiftUI

public struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    
    public init(appViewModel: AppViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(appViewModel: appViewModel))
    }
    
    public var body: some View {
        ZStack {
            // Nền đen phong cách điện ảnh
            Color.black.ignoresSafeArea()
            
            // Lớp nền trang trí thêm
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
                    VStack(spacing: 15) {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        SecureField("Mật khẩu", text: $viewModel.password)
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
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Nút đăng nhập
                    Button {
                        viewModel.loginButtonTapped()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#D4AF37"))
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("ĐĂNG NHẬP")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(height: 55)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

import SwiftUI

public struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    
    // Animation states
    @State private var animateGradients = false
    
    public init(appViewModel: AppViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(appViewModel: appViewModel))
    }
    
    public var body: some View {
        ZStack {
            // Nền Background động (Animated Gradient)
            LinearGradient(
                colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")],
                startPoint: animateGradients ? .topLeading : .bottomLeading,
                endPoint: animateGradients ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                    animateGradients.toggle()
                }
            }
            
            // Hiệu ứng hạt bụi (Dust / Stars) giả lập không gian rạp phim
            Circle()
                .fill(Color(hex: "#D4AF37").opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -100, y: -200)
            
            VStack(spacing: 35) {
                
                // Tiêu đề App (Logo)
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(Color(hex: "#D4AF37"))
                        .padding(.bottom, 5)
                    
                    Text("Cinematicket")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text(viewModel.isLoginMode ? "Đăng nhập để đặt vé" : "Tạo tài khoản mới")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                // Form nhập liệu (Glassmorphism)
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        
                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            TextField("Email", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        
                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            SecureField("Mật khẩu", text: $viewModel.password)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        
                        // Confirm Password Field (Chỉ hiện khi Đăng ký)
                        if !viewModel.isLoginMode {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 30)
                                SecureField("Xác nhận Mật khẩu", text: $viewModel.confirmPassword)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial) // Hiệu ứng kính mờ
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(Color(hex: "#FF4D4D"))
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    // Nút Hành động chính
                    Button {
                        viewModel.authenticate()
                    } label: {
                        ZStack {
                            LinearGradient(
                                colors: [Color(hex: "#D4AF37"), Color(hex: "#AA801E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(16)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text(viewModel.isLoginMode ? "ĐĂNG NHẬP" : "ĐĂNG KÝ")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .shadow(color: .white.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .frame(height: 55)
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Nút chuyển chế độ
                    Button {
                        withAnimation(.spring()) {
                            viewModel.toggleMode()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.isLoginMode ? "Chưa có tài khoản?" : "Đã có tài khoản?")
                                .foregroundColor(.gray)
                            Text(viewModel.isLoginMode ? "Đăng ký ngay" : "Đăng nhập")
                                .foregroundColor(Color(hex: "#D4AF37"))
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 15))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

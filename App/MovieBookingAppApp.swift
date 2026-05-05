import SwiftUI
import FirebaseCore

// Tạo AppDelegate để khởi tạo Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        print("✅ Đã khởi tạo Firebase thành công!")
        
        return true
    }
}

@main
struct MovieBookingAppApp: App {
    // Kết nối AppDelegate vào chu kỳ sống của SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Khởi tạo ViewModel tổng quản lý trạng thái của App
    @StateObject private var appViewModel = AppViewModel()
    
    // Trạng thái cho lớp che mờ bảo mật
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyOverlay = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Điều hướng màn hình dựa vào trạng thái đăng nhập
                if appViewModel.isAuthenticated {
                    // Màn hình chính tạm thời với nút Đăng xuất
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#D4AF37"))
                        
                        Text("Đăng nhập thành công!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Trang chủ sẽ được xây dựng ở Sprint 2")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Nút Đăng xuất
                        Button {
                            appViewModel.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Đăng xuất")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(14)
                        }
                        .padding(.bottom, 60)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                } else {
                    // Hiển thị màn hình đăng nhập đầu tiên
                    LoginView(appViewModel: appViewModel)
                }
                
                // Lớp che mờ bảo mật khi app chuyển sang background
                if showPrivacyOverlay {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "#D4AF37"))
                            Text("Cinematicket")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    // Người dùng quay lại App → ẩn lớp che
                    withAnimation(.easeOut(duration: 0.2)) {
                        showPrivacyOverlay = false
                    }
                case .inactive, .background:
                    // App bị thu nhỏ hoặc chuyển sang background → hiện lớp che
                    withAnimation {
                        showPrivacyOverlay = true
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}

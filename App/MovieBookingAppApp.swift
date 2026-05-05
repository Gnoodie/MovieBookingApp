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
    
    var body: some Scene {
        WindowGroup {
            // Điều hướng màn hình dựa vào trạng thái đăng nhập
            if appViewModel.isAuthenticated {
                // Màn hình chính (Sẽ tạo sau)
                Text("Trang Chủ (Sắp làm)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                // Hiển thị màn hình đăng nhập đầu tiên
                LoginView(appViewModel: appViewModel)
            }
        }
    }
}

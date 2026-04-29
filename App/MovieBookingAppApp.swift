import SwiftUI
import ComposableArchitecture

// Nhúng thư viện Firebase
#if canImport(FirebaseCore)
import FirebaseCore
#endif

// Tạo AppDelegate để khởi tạo Firebase (Chuẩn theo tài liệu của Google)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        print("✅ Đã khởi tạo Firebase thành công!")
        #endif
        
        return true
    }
}

@main
struct MovieBookingAppApp: App {
    // Kết nối AppDelegate vào chu kỳ sống của SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Khởi tạo Store tổng (AppStore) chứa toàn bộ trạng thái của App
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            // Hiển thị màn hình đăng nhập đầu tiên
            LoginView(
                store: MovieBookingAppApp.store.scope(state: \.auth, action: \.auth)
            )
        }
    }
}

import SwiftUI
import FirebaseCore

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("✅ Firebase đã khởi tạo thành công!")
        return true
    }
}

// MARK: - Main App

@main
struct MovieBookingAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var router = AppRouter()

    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyOverlay = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(router)
                        .environmentObject(appViewModel)
                } else {
                    LoginView(appViewModel: appViewModel)
                }

                // Privacy overlay khi app vào background
                if showPrivacyOverlay {
                    PrivacyOverlayView()
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                withAnimation(.easeOut(duration: 0.2)) {
                    showPrivacyOverlay = (newPhase == .inactive || newPhase == .background)
                }
            }
            // MARK: - URL Scheme Handler (Phase 6.2)
            // Xử lý callback từ MoMo/VNPay: cinematicket://payment/callback?...
            .onOpenURL { url in
                router.handleDeepLink(url)
                router.handleIntentURL(url, appViewModel: appViewModel)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {
            // Tab 1: Phim (Home)
            HomeView()
            .environmentObject(router)
            .tabItem {
                Label("Phim", systemImage: "film")
            }
            .tag(AppViewModel.Tab.home)

            SearchView()
                .tabItem {
                    Label("Khám phá", systemImage: "magnifyingglass")
                }
                .tag(AppViewModel.Tab.search)

            // Tab 3: Vé của tôi
            MyTicketsView()
                .environmentObject(router)
                .tabItem {
                    Label("Vé", systemImage: "ticket.fill")
                }
                .tag(AppViewModel.Tab.tickets)

            // Tab 4: Hồ sơ
            ProfileView()
                .environmentObject(appViewModel)
                .tabItem {
                    Label("Tôi", systemImage: "person.circle")
                }
                .tag(AppViewModel.Tab.profile)
        }
        .tint(Color(hex: "#D4AF37"))
        .onAppear {
            // Style tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#0D0D1A"))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Privacy Overlay

private struct PrivacyOverlayView: View {
    var body: some View {
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
    }
}


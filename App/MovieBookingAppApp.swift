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
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Phim (Home)
            HomeView()
            .environmentObject(router)
            .tabItem {
                Label("Phim", systemImage: "film")
            }
            .tag(0)

            // Tab 2: Tìm kiếm
            PlaceholderView(title: "Tìm kiếm — Sprint 2+")
                .tabItem {
                    Label("Khám phá", systemImage: "magnifyingglass")
                }
                .tag(1)

            // Tab 3: Vé của tôi
            PlaceholderView(title: "Vé của tôi — Sprint 4")
                .tabItem {
                    Label("Vé", systemImage: "ticket.fill")
                }
                .tag(2)

            // Tab 4: Hồ sơ
            PlaceholderView(title: "Hồ sơ — Sprint 5")
                .tabItem {
                    Label("Tôi", systemImage: "person.circle")
                }
                .tag(3)
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


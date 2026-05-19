import Foundation

// MARK: - AppRoute

/// Centralized navigation enum cho toàn bộ app
/// Dùng cho deep link và điều hướng đa màn hình
enum AppRoute: Hashable {
    case home
    case movieDetail(Movie)
    case showtimePicker(movie: Movie)
    case seatMap(showtime: Showtime, movie: Movie)                                          // Sprint 3
    case fnbMenu(seats: [Seat], showtime: Showtime, movie: Movie)                           // Sprint 4
    case checkout(seats: [Seat], showtime: Showtime, movie: Movie, fnbItems: [FnBOrderItem]) // Sprint 4
    case bookingSuccess(order: Order, ticket: Ticket)                                        // Sprint 4
    case eTicket(ticket: Ticket)                                                             // Sprint 4
}

// MARK: - AppRouter

/// Quản lý NavigationPath cho toàn app
@MainActor
final class AppRouter: ObservableObject {

    @Published var path: [AppRoute] = []

    // MARK: Navigation Actions

    func navigateTo(_ route: AppRoute) {
        path.append(route)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path.removeAll()
    }

    /// Deep link handler — parse URL scheme
    func handleDeepLink(_ url: URL) {
        // cinematicket://movie/{id}
        // cinematicket://ticket/{id}
        // cinematicket://payment/callback?... (MoMo/VNPay)
        guard url.scheme == "cinematicket" else { return }
        let host = url.host ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "movie":
            if let movieId = components.first {
                // Sẽ load movie rồi navigate — xử lý ở HomeView
                // Deep link: cinematicket://movie/{movieId}
                break
            }
        case "ticket":
            if let _ = components.first {
                // Deep link: cinematicket://ticket/{ticketId}
                break
            }
        case "payment":
            // MoMo/VNPay callback — delegate cho PaymentService
            // Deep link: cinematicket://payment/callback?resultCode=0&...
            PaymentService.shared.handleCallback(url: url)
        default:
            break
        }
    }
    
    /// Deep link handler cho App Intents (Siri / Spotlight)
    func handleIntentURL(_ url: URL, appViewModel: AppViewModel) {
        guard url.scheme == "cinematicket" else { return }
        
        if url.host == "tickets" {
            appViewModel.selectedTab = .tickets
        } else if url.host == "search" {
            appViewModel.selectedTab = .search
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItem = components.queryItems?.first(where: { $0.name == "q" }),
               let query = queryItem.value {
                NotificationCenter.default.post(name: NSNotification.Name("SearchIntent"), object: query)
            }
        }
    }
}

import Foundation

// MARK: - AppRoute

/// Centralized navigation enum cho toàn bộ app
/// Dùng cho deep link và điều hướng đa màn hình
enum AppRoute: Hashable {
    case home
    case movieDetail(Movie)
    case showtimePicker(movie: Movie)
    case seatMap(showtime: Showtime, movie: Movie)   // Sprint 3
    case checkout                                     // Sprint 4
    case eTicket(ticketId: String)                   // Sprint 4
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
        guard url.scheme == "cinematicket" else { return }
        let host = url.host ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "movie":
            if let movieId = components.first {
                // Sẽ load movie rồi navigate — xử lý ở HomeView
                print("🔗 Deep link to movie: \(movieId)")
            }
        case "ticket":
            if let ticketId = components.first {
                path = [.eTicket(ticketId: ticketId)]
            }
        default:
            break
        }
    }
}

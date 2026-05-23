import Foundation
import Combine

// MARK: - Movie Filter

enum MovieFilter: String, CaseIterable, Equatable {
    case all    = "Tất cả"
    case twoD   = "2D"
    case threeD = "3D"
    case imax   = "IMAX"
    case action = "Hành động"
    case comedy = "Hài"
    case horror = "Kinh dị"
    case drama  = "Tâm lý"

    var genreKey: String? {
        switch self {
        case .action: return "Hành động"
        case .comedy: return "Hài hước"
        case .horror: return "Kinh dị"
        case .drama:  return "Tâm lý"
        default: return nil
        }
    }

    var formatKey: String? {
        switch self {
        case .twoD:   return "2D"
        case .threeD: return "3D"
        case .imax:   return "IMAX"
        default: return nil
        }
    }
}

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [Movie]    = []
    @Published var nowPlayingMovies: [Movie]  = []
    @Published var comingSoonMovies: [Movie]  = []
    @Published var filteredMovies: [Movie]    = []
    @Published var selectedFilter: MovieFilter = .all { didSet { applyFilter() } }
    @Published var searchQuery: String = ""   { didSet { applyFilter() } }
    @Published var isLoading: Bool    = false
    @Published var errorMessage: String? = nil

    var heroMovies:    [Movie] { Array(trendingMovies.prefix(5)) }
    var displayMovies: [Movie] { filteredMovies }

    private let movieRepository: MovieRepositoryProtocol

    init(movieRepository: MovieRepositoryProtocol = MockMovieRepository()) {
        self.movieRepository = movieRepository
    }

    func onAppear() {
        guard trendingMovies.isEmpty else { return }
        loadMovies()
    }

    func loadMovies() {
    isLoading    = true
    errorMessage = nil

    Task { @MainActor in          // ← Thêm @MainActor vào Task
        do {
            let (nowPlaying, comingSoon) = try await (
                movieRepository.fetchNowPlaying(),
                movieRepository.fetchComingSoon()
            )
            // Tất cả code bên dưới chạy trên Main Thread ✅
            self.trendingMovies   = nowPlaying
            self.nowPlayingMovies = nowPlaying
            self.comingSoonMovies = comingSoon
            self.filteredMovies   = nowPlaying
            self.isLoading        = false
            self.applyFilter()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading    = false
        }
    }
}

    func pullToRefresh() async {
        trendingMovies   = []
        nowPlayingMovies = []
        comingSoonMovies = []
        loadMovies()
    }

    private func applyFilter() {
        var movies = nowPlayingMovies
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            movies = movies.filter {
                $0.title.lowercased().contains(q) ||
                $0.originalTitle.lowercased().contains(q)
            }
        }
        if let genreKey = selectedFilter.genreKey {
            movies = movies.filter { $0.genre.contains(genreKey) }
        }
        filteredMovies = movies
    }
}

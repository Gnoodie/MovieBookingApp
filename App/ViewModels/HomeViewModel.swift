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
    @Published var trendingMovies: [Movie] = []
    @Published var nowPlayingMovies: [Movie] = []
    @Published var comingSoonMovies: [Movie] = []
    @Published var filteredMovies: [Movie] = []
    
    @Published var selectedFilter: MovieFilter = .all {
        didSet { applyFilter() }
    }
    
    @Published var searchQuery: String = "" {
        didSet { applyFilter() }
    }
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var heroMovies: [Movie] {
        Array(trendingMovies.prefix(5))
    }
    
    var displayMovies: [Movie] {
        filteredMovies
    }
    
    // Dependencies
    private let movieRepository: MovieRepositoryProtocol
    
    init(movieRepository: MovieRepositoryProtocol = MockMovieRepository()) {
        self.movieRepository = movieRepository
    }
    
    func onAppear() {
        guard trendingMovies.isEmpty else { return }
        loadMovies()
    }
    
    func loadMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let trending = movieRepository.fetchNowPlaying()
                async let nowPlaying = movieRepository.fetchNowPlaying()
                async let comingSoon = movieRepository.fetchComingSoon()
                
                let t = try await trending
                let np = try await nowPlaying
                let cs = try await comingSoon
                
                // Đảm bảo cập nhật các thuộc tính @Published tuyệt đối trên Main Thread
                await MainActor.run {
                    self.trendingMovies = t
                    self.nowPlayingMovies = np
                    self.comingSoonMovies = cs
                    self.filteredMovies = np
                    self.isLoading = false
                    self.applyFilter()
                }
            } catch {
                let localError = error
                await MainActor.run {
                    self.errorMessage = localError.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func pullToRefresh() async {
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
        
        switch selectedFilter {
        case .all:
            break
        case .twoD, .threeD, .imax:
            break
        default:
            if let genreKey = selectedFilter.genreKey {
                movies = movies.filter { $0.genre.contains(genreKey) }
            }
        }
        
        filteredMovies = movies
    }
}

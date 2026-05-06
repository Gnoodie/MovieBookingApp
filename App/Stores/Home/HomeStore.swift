import Foundation
import ComposableArchitecture

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

// MARK: - HomeFeature (TCA Reducer)

@Reducer
struct HomeFeature {

    // MARK: State

    @ObservableState
    struct State: Equatable {
        var trendingMovies: [Movie]    = []
        var nowPlayingMovies: [Movie]  = []
        var comingSoonMovies: [Movie]  = []
        var filteredMovies: [Movie]    = []
        var selectedFilter: MovieFilter = .all
        var searchQuery: String        = ""
        var isLoading: Bool            = false
        var errorMessage: String?      = nil
        var selectedMovieId: String?   = nil   // Dùng cho navigation

        // Phim hiển thị trong Hero Carousel (top 5 trending)
        var heroMovies: [Movie] {
            Array(trendingMovies.prefix(5))
        }

        // Phim sau khi áp filter + search
        var displayMovies: [Movie] {
            filteredMovies
        }
    }

    // MARK: Action

    enum Action: BindableAction {
        // Lifecycle
        case onAppear
        case onDisappear

        // Loading
        case loadMovies
        case moviesResponse(trending: [Movie], nowPlaying: [Movie], comingSoon: [Movie])
        case loadingFailed(Error)

        // User Interaction
        case binding(BindingAction<State>)
        case filterChanged(MovieFilter)
        case searchQueryChanged(String)
        case movieTapped(Movie)
        case pullToRefresh

        // Internal
        case applyFilter
    }

    // MARK: Dependencies

    @Dependency(\.movieRepository) var movieRepository

    // MARK: Reducer Body

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case .onAppear:
                guard state.trendingMovies.isEmpty else { return .none }
                return .send(.loadMovies)

            case .onDisappear:
                return .none

            case .loadMovies, .pullToRefresh:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        async let trending   = movieRepository.fetchNowPlaying()
                        async let nowPlaying = movieRepository.fetchNowPlaying()
                        async let comingSoon = movieRepository.fetchComingSoon()
                        await send(.moviesResponse(
                            trending:   try await trending,
                            nowPlaying: try await nowPlaying,
                            comingSoon: try await comingSoon
                        ))
                    } catch {
                        await send(.loadingFailed(error))
                    }
                }

            case let .moviesResponse(trending, nowPlaying, comingSoon):
                state.isLoading = false
                state.trendingMovies   = trending
                state.nowPlayingMovies = nowPlaying
                state.comingSoonMovies = comingSoon
                state.filteredMovies   = nowPlaying
                return .send(.applyFilter)

            case let .loadingFailed(error):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .filterChanged(filter):
                state.selectedFilter = filter
                return .send(.applyFilter)

            case let .searchQueryChanged(query):
                state.searchQuery = query
                return .send(.applyFilter)

            case .applyFilter:
                var movies = state.nowPlayingMovies

                // Search filter
                if !state.searchQuery.isEmpty {
                    let q = state.searchQuery.lowercased()
                    movies = movies.filter {
                        $0.title.lowercased().contains(q) ||
                        $0.originalTitle.lowercased().contains(q)
                    }
                }

                // Category/format filter
                switch state.selectedFilter {
                case .all:
                    break
                case .twoD, .threeD, .imax:
                    // Format filters — phim có thể chiếu theo format này
                    // Client-side filter bằng genre hoặc metadata
                    break
                default:
                    if let genreKey = state.selectedFilter.genreKey {
                        movies = movies.filter { $0.genre.contains(genreKey) }
                    }
                }

                state.filteredMovies = movies
                return .none

            case let .movieTapped(movie):
                state.selectedMovieId = movie.id
                return .none

            case .binding:
                return .none
            }
        }
    }
}

// MARK: - Dependency Key

extension DependencyValues {
    var movieRepository: any MovieRepositoryProtocol {
        get { self[MovieRepositoryKey.self] }
        set { self[MovieRepositoryKey.self] = newValue }
    }
}

private enum MovieRepositoryKey: DependencyKey {
    static let liveValue: any MovieRepositoryProtocol = MockMovieRepository()
    static let testValue: any MovieRepositoryProtocol = MockMovieRepository()
}

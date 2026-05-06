import Foundation
import ComposableArchitecture

// MARK: - MovieDetailFeature (TCA Reducer)

@Reducer
struct MovieDetailFeature {

    // MARK: State

    @ObservableState
    struct State: Equatable {
        var movie: Movie
        var isLoadingDetail: Bool = false
        var isFavorite: Bool = false
        var isTrailerPlaying: Bool = false
        var errorMessage: String? = nil

        init(movie: Movie) {
            self.movie = movie
        }
    }

    // MARK: Action

    enum Action {
        // Lifecycle
        case onAppear
        case onDisappear

        // User Interaction
        case toggleFavorite
        case buyTicketsTapped
        case trailerTapped
        case trailersStartedPlaying
        case trailerStopped

        // Loading
        case loadDetail
        case detailResponse(Movie)
        case loadingFailed(Error)
    }

    // MARK: Dependencies

    @Dependency(\.movieRepository) var movieRepository

    // MARK: Reducer Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                return .send(.loadDetail)

            case .onDisappear:
                state.isTrailerPlaying = false
                return .none

            case .loadDetail:
                state.isLoadingDetail = true
                let movieId = state.movie.id
                return .run { send in
                    do {
                        let detail = try await movieRepository.fetchMovieDetail(id: movieId)
                        await send(.detailResponse(detail))
                    } catch {
                        await send(.loadingFailed(error))
                    }
                }

            case let .detailResponse(movie):
                state.isLoadingDetail = false
                state.movie = movie
                return .none

            case let .loadingFailed(error):
                state.isLoadingDetail = false
                state.errorMessage = error.localizedDescription
                return .none

            case .toggleFavorite:
                state.isFavorite.toggle()
                return .none

            case .buyTicketsTapped:
                // Navigation xử lý bởi parent (AppStore)
                return .none

            case .trailerTapped:
                state.isTrailerPlaying = true
                return .none

            case .trailersStartedPlaying:
                state.isTrailerPlaying = true
                return .none

            case .trailerStopped:
                state.isTrailerPlaying = false
                return .none
            }
        }
    }
}

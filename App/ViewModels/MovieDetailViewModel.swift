import Foundation
import Combine

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var movie: Movie
    @Published var isLoadingDetail: Bool = false
    @Published var isFavorite: Bool = false
    @Published var isTrailerPlaying: Bool = false
    @Published var errorMessage: String? = nil

    private let movieRepository: MovieRepositoryProtocol

    init(movie: Movie, movieRepository: MovieRepositoryProtocol = MockMovieRepository()) {
        self.movie = movie
        self.movieRepository = movieRepository
    }

    func onAppear() {
        loadDetail()
    }

    func onDisappear() {
        isTrailerPlaying = false
    }

    func loadDetail() {
        isLoadingDetail = true
        let movieId = movie.id
        
        Task {
            do {
                let detail = try await movieRepository.fetchMovieDetail(id: movieId)
                self.movie = detail
                self.isLoadingDetail = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingDetail = false
            }
        }
    }

    func toggleFavorite() {
        isFavorite.toggle()
    }

    func trailerTapped() {
        isTrailerPlaying = true
    }

    func trailersStartedPlaying() {
        isTrailerPlaying = true
    }

    func trailerStopped() {
        isTrailerPlaying = false
    }
}

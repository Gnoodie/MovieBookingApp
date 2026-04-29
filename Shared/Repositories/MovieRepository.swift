import Foundation

// MARK: - Movie Repository Protocol

protocol MovieRepositoryProtocol {
    func fetchNowPlaying() async throws -> [Movie]
    func fetchComingSoon() async throws -> [Movie]
    func fetchMovieDetail(id: String) async throws -> Movie
    func searchMovies(query: String) async throws -> [Movie]
}

// MARK: - Mock Implementation

struct MockMovieRepository: MovieRepositoryProtocol {
    func fetchNowPlaying() async throws -> [Movie] {
        return Movie.mocks
    }
    
    func fetchComingSoon() async throws -> [Movie] {
        return []
    }
    
    func fetchMovieDetail(id: String) async throws -> Movie {
        if let movie = Movie.mocks.first(where: { $0.id == id }) {
            return movie
        }
        throw NSError(domain: "MovieRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Movie not found"])
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        let lowercasedQuery = query.lowercased()
        return Movie.mocks.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.originalTitle.lowercased().contains(lowercasedQuery)
        }
    }
}

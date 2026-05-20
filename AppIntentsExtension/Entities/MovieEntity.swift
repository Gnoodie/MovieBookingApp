import AppIntents
import CoreSpotlight

@available(iOS 18.0, *)
struct MovieEntity: AppEntity, IndexedEntity {
    var id: String
    
    @Property(title: "Tên phim")
    var title: String
    
    @Property(title: "Thể loại")
    var genre: String
    
    init(id: String, title: String, genre: String = "Giải trí") {
        self.id = id
        self.title = title
        self.genre = genre
    }
    
    static var defaultQuery = MovieEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Phim"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(genre)")
    }
}

@available(iOS 18.0, *)
struct MovieEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [MovieEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreMovieRepository()
        var results = [MovieEntity]()
        for id in identifiers {
            if let movie = try? await repo.fetchMovieDetail(id: id) {
                results.append(MovieEntity(id: movie.id, title: movie.title, genre: movie.genre.first ?? "Phim"))
            }
        }
        return results
    }
    
    func entities(matching string: String) async throws -> [MovieEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreMovieRepository()
        let movies = try await repo.searchMovies(query: string)
        return movies.map { MovieEntity(id: $0.id, title: $0.title, genre: $0.genre.first ?? "Phim") }
    }
    
    func suggestedEntities() async throws -> [MovieEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreMovieRepository()
        let movies = try await repo.fetchNowPlaying()
        return movies.map { MovieEntity(id: $0.id, title: $0.title, genre: $0.genre.first ?? "Phim") }
    }
}

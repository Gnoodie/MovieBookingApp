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
        return identifiers.map { MovieEntity(id: $0, title: "Phim \($0)") }
    }
    
    func entities(matching string: String) async throws -> [MovieEntity] {
        return [
            MovieEntity(id: "spider-man", title: "Người Nhện", genre: "Hành động"),
            MovieEntity(id: "avatar", title: "Avatar", genre: "Khoa học viễn tưởng")
        ].filter { $0.title.lowercased().contains(string.lowercased()) }
    }
    
    func suggestedEntities() async throws -> [MovieEntity] {
        return [
            MovieEntity(id: "spider-man", title: "Người Nhện", genre: "Hành động"),
            MovieEntity(id: "avatar", title: "Avatar", genre: "Khoa học viễn tưởng")
        ]
    }
}

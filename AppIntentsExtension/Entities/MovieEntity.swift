import AppIntents

@available(iOS 17.0, *)
struct MovieEntity: AppEntity {
    var id: String
    var title: String

    static var defaultQuery = MovieEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Phim"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

@available(iOS 17.0, *)
struct MovieEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MovieEntity] {
        return identifiers.map { MovieEntity(id: $0, title: "Phim \($0)") }
    }
    
    func suggestedEntities() async throws -> [MovieEntity] {
        return [
            MovieEntity(id: "spider-man", title: "Người Nhện"),
            MovieEntity(id: "avatar", title: "Avatar")
        ]
    }
}

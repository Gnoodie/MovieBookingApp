import AppIntents
import CoreSpotlight

@available(iOS 18.0, *)
struct CinemaEntity: AppEntity, IndexedEntity {
    var id: String
    
    @Property(title: "Tên Rạp")
    var name: String
    
    @Property(title: "Địa chỉ")
    var location: String
    
    init(id: String, name: String, location: String) {
        self.id = id
        self.name = name
        self.location = location
    }
    
    static var defaultQuery = CinemaEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Rạp Phim"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(location)")
    }
}

@available(iOS 18.0, *)
struct CinemaEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CinemaEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreCinemaRepository()
        let allCinemas = try? await repo.fetchCinemas()
        return (allCinemas ?? []).filter { identifiers.contains($0.id) }
            .map { CinemaEntity(id: $0.id, name: $0.name, location: $0.district) }
    }
    
    func entities(matching string: String) async throws -> [CinemaEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreCinemaRepository()
        let allCinemas = try? await repo.fetchCinemas()
        let lowercased = string.lowercased()
        return (allCinemas ?? []).filter { $0.name.lowercased().contains(lowercased) }
            .map { CinemaEntity(id: $0.id, name: $0.name, location: $0.district) }
    }
    
    func suggestedEntities() async throws -> [CinemaEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let repo = FirestoreCinemaRepository()
        let allCinemas = try? await repo.fetchCinemas()
        return (allCinemas ?? []).map { CinemaEntity(id: $0.id, name: $0.name, location: $0.district) }
    }
}

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
        return identifiers.map { CinemaEntity(id: $0, name: "Rạp \($0)", location: "TP.HCM") }
    }
    
    func entities(matching string: String) async throws -> [CinemaEntity] {
        return [
            CinemaEntity(id: "cgv-svh", name: "CGV Sư Vạn Hạnh", location: "Quận 10, TP.HCM"),
            CinemaEntity(id: "lotte-q7", name: "Lotte Cinema Quận 7", location: "Quận 7, TP.HCM")
        ].filter { $0.name.lowercased().contains(string.lowercased()) }
    }
    
    func suggestedEntities() async throws -> [CinemaEntity] {
        return [
            CinemaEntity(id: "cgv-svh", name: "CGV Sư Vạn Hạnh", location: "Quận 10, TP.HCM"),
            CinemaEntity(id: "lotte-q7", name: "Lotte Cinema Quận 7", location: "Quận 7, TP.HCM")
        ]
    }
}

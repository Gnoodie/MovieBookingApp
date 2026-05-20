import AppIntents
import CoreSpotlight

@available(iOS 18.0, *)
struct ShowtimeEntity: AppEntity, IndexedEntity {
    var id: String
    
    @Property(title: "Thời gian chiếu")
    var timeString: String
    
    @Property(title: "Định dạng")
    var format: String
    
    init(id: String, timeString: String, format: String) {
        self.id = id
        self.timeString = timeString
        self.format = format
    }
    
    static var defaultQuery = ShowtimeEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Suất Chiếu"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(timeString)", subtitle: "\(format)")
    }
}

@available(iOS 18.0, *)
struct ShowtimeEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ShowtimeEntity] {
        return identifiers.map { ShowtimeEntity(id: $0, timeString: "19:00", format: "2D") }
    }
    
    func entities(matching string: String) async throws -> [ShowtimeEntity] {
        return try await suggestedEntities()
    }
    
    func suggestedEntities() async throws -> [ShowtimeEntity] {
        return [
            ShowtimeEntity(id: "st-1", timeString: "19:00 Hôm nay", format: "IMAX 3D"),
            ShowtimeEntity(id: "st-2", timeString: "21:30 Hôm nay", format: "2D")
        ]
    }
}

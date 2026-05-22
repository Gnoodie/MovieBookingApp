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

import FirebaseFirestore

@available(iOS 18.0, *)
struct ShowtimeEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ShowtimeEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let db = Firestore.firestore()
        var results = [ShowtimeEntity]()
        for id in identifiers {
            if let doc = try? await db.collection("showtimes").document(id).getDocument(),
               let data = doc.data() {
                let format = data["format"] as? String ?? "2D"
                let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm dd/MM"
                results.append(ShowtimeEntity(id: id, timeString: formatter.string(from: startTime), format: format))
            }
        }
        return results
    }
    
    func entities(matching string: String) async throws -> [ShowtimeEntity] {
        return try await suggestedEntities()
    }
    
    func suggestedEntities() async throws -> [ShowtimeEntity] {
        FirebaseIntentSetup.configureIfNeeded()
        let db = Firestore.firestore()
        // Chỉ lấy những suất chiếu chưa bắt đầu (startTime > hiện tại), sắp xếp gần nhất trước
        let now = Timestamp(date: Date())
        let snapshot = try? await db.collection("showtimes")
            .whereField("startTime", isGreaterThan: now)
            .order(by: "startTime", descending: false)
            .limit(to: 20)
            .getDocuments()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM"
        return (snapshot?.documents ?? []).compactMap { doc in
            let data = doc.data()
            let format = data["format"] as? String ?? "2D"
            let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
            return ShowtimeEntity(id: doc.documentID, timeString: formatter.string(from: startTime), format: format)
        }
    }
}

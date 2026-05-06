import Foundation
import FirebaseFirestore

// MARK: - Firestore Cinema Repository

/// Repository đọc dữ liệu rạp từ Firebase Firestore
/// Collection: "cinemas"
final class FirestoreCinemaRepository: ShowtimeRepositoryProtocol {

    private let db = Firestore.firestore()
    private let moviesCollection = "movies"
    private let cinemasCollection = "cinemas"
    private let showtimesCollection = "showtimes"

    // MARK: - ShowtimeRepositoryProtocol

    func fetchCinemas() async throws -> [Cinema] {
        let snapshot = try await db.collection(cinemasCollection)
            .order(by: "name")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try FirestoreCinemaMapper.map(id: doc.documentID, data: doc.data())
        }
    }

    func fetchShowtimes(movieId: String, date: Date) async throws -> [Showtime] {
        let dateString = ShowtimeAPI.dateString(from: date)

        // Query showtimes theo movieId và ngày
        let snapshot = try await db.collection(showtimesCollection)
            .whereField("movieId", isEqualTo: movieId)
            .whereField("date", isEqualTo: dateString)
            .order(by: "startTime")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try FirestoreShowtimeMapper.map(id: doc.documentID, data: doc.data())
        }
    }

    func fetchShowtimesByDate(movieId: String, cinemaId: String, date: Date) async throws -> [Showtime] {
        let dateString = ShowtimeAPI.dateString(from: date)

        let snapshot = try await db.collection(showtimesCollection)
            .whereField("movieId",  isEqualTo: movieId)
            .whereField("cinemaId", isEqualTo: cinemaId)
            .whereField("date",     isEqualTo: dateString)
            .order(by: "startTime")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try FirestoreShowtimeMapper.map(id: doc.documentID, data: doc.data())
        }
    }
}

// MARK: - Cinema Mapper

enum FirestoreCinemaMapper {
    static func map(id: String, data: [String: Any]) throws -> Cinema {
        guard let name = data["name"] as? String else {
            throw FirestoreRepositoryError.missingField("name")
        }

        let brandRaw   = data["brand"]    as? String ?? "Other"
        let address    = data["address"]  as? String ?? ""
        let city       = data["city"]     as? String ?? ""
        let district   = data["district"] as? String ?? ""
        let latitude   = data["latitude"]  as? Double ?? 0.0
        let longitude  = data["longitude"] as? Double ?? 0.0
        let phone      = data["phoneNumber"] as? String
        let amenitiesRaw = data["amenities"] as? [String] ?? []

        let brand = Cinema.Brand(rawValue: brandRaw) ?? .other
        let amenities = amenitiesRaw.compactMap { Cinema.Amenity(rawValue: $0) }

        // Halls mapping (đơn giản hóa — từ sub-collection hoặc embedded array)
        let hallsRaw = data["halls"] as? [[String: Any]] ?? []
        let halls: [Cinema.Hall] = hallsRaw.compactMap { hallData in
            guard
                let hallId   = hallData["id"]   as? String,
                let hallName = hallData["name"]  as? String,
                let typeRaw  = hallData["type"]  as? String,
                let total    = hallData["totalSeats"] as? Int,
                let rows     = hallData["rowCount"]   as? Int,
                let perRow   = hallData["seatsPerRow"] as? Int
            else { return nil }
            let hallType = Cinema.Hall.HallType(rawValue: typeRaw) ?? .standard
            return Cinema.Hall(id: hallId, name: hallName, type: hallType,
                               totalSeats: total, rowCount: rows, seatsPerRow: perRow)
        }

        return Cinema(
            id: id,
            name: name,
            brand: brand,
            address: address,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude,
            phoneNumber: phone,
            halls: halls,
            amenities: amenities
        )
    }

    /// Chuyển Cinema thành dictionary để seed lên Firestore
    static func toFirestore(_ cinema: Cinema) -> [String: Any] {
        [
            "name":     cinema.name,
            "brand":    cinema.brand.rawValue,
            "address":  cinema.address,
            "city":     cinema.city,
            "district": cinema.district,
            "latitude":  cinema.latitude,
            "longitude": cinema.longitude,
            "phoneNumber": cinema.phoneNumber as Any,
            "amenities": cinema.amenities.map { $0.rawValue },
            "halls": cinema.halls.map { hall in
                [
                    "id":         hall.id,
                    "name":       hall.name,
                    "type":       hall.type.rawValue,
                    "totalSeats": hall.totalSeats,
                    "rowCount":   hall.rowCount,
                    "seatsPerRow": hall.seatsPerRow,
                ] as [String: Any]
            },
        ]
    }
}

// MARK: - Showtime Mapper

enum FirestoreShowtimeMapper {
    static func map(id: String, data: [String: Any]) throws -> Showtime {
        guard let movieId  = data["movieId"]  as? String,
              let cinemaId = data["cinemaId"] as? String,
              let hallId   = data["hallId"]   as? String
        else { throw FirestoreRepositoryError.missingField("movieId/cinemaId/hallId") }

        let langRaw    = data["language"]         as? String ?? "EN"
        let subLangRaw = data["subtitleLanguage"] as? String
        let formatRaw  = data["format"]           as? String ?? "2D"
        let basePrice  = data["basePrice"]        as? Double ?? 0
        let available  = data["availableSeats"]   as? Int ?? 0
        let total      = data["totalSeats"]       as? Int ?? 0

        let startTime: Date
        let endTime: Date
        if let ts = data["startTime"] as? Timestamp {
            startTime = ts.dateValue()
        } else { startTime = Date() }
        if let ts = data["endTime"] as? Timestamp {
            endTime = ts.dateValue()
        } else { endTime = Date() }

        return Showtime(
            id: id,
            movieId: movieId,
            cinemaId: cinemaId,
            hallId: hallId,
            startTime: startTime,
            endTime: endTime,
            language: Showtime.Language(rawValue: langRaw) ?? .english,
            subtitleLanguage: subLangRaw.flatMap { Showtime.Language(rawValue: $0) },
            format: Showtime.Format(rawValue: formatRaw) ?? .twoD,
            basePrice: Decimal(basePrice),
            availableSeats: available,
            totalSeats: total
        )
    }
}

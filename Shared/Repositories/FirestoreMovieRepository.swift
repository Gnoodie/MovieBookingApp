import Foundation
import FirebaseFirestore

// MARK: - Firestore Movie Repository

/// Repository đọc dữ liệu phim từ Firebase Firestore
/// Collection: "movies"
/// Document fields phải map với Movie struct (dùng Codable + @DocumentID)
final class FirestoreMovieRepository: MovieRepositoryProtocol {

    private let db = Firestore.firestore()
    private let collection = "movies"

    func fetchNowPlaying() async throws -> [Movie] {
        let snapshot = try await db.collection(collection)
            .whereField("isNowPlaying", isEqualTo: true)
            .order(by: "rating", descending: true)
            .limit(to: 20)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try mapDocument(doc)
        }
    }

    func fetchComingSoon() async throws -> [Movie] {
        let snapshot = try await db.collection(collection)
            .whereField("isNowPlaying", isEqualTo: false)
            .order(by: "releaseDate", descending: false)
            .limit(to: 20)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try mapDocument(doc)
        }
    }

    func fetchMovieDetail(id: String) async throws -> Movie {
        let doc = try await db.collection(collection).document(id).getDocument()

        guard doc.exists else {
            throw FirestoreRepositoryError.documentNotFound(id: id)
        }
        return try mapDocument(doc)
    }

    func searchMovies(query: String) async throws -> [Movie] {
        // Firestore không hỗ trợ full-text search native
        // Workaround: fetch all rồi filter client-side (phù hợp cho dự án nhỏ)
        // Production: dùng Algolia hoặc Firebase Extensions Search
        let snapshot = try await db.collection(collection)
            .order(by: "title")
            .getDocuments()

        let lowercased = query.lowercased()
        return try snapshot.documents
            .compactMap { try? mapDocument($0) }
            .filter {
                $0.title.lowercased().contains(lowercased) ||
                $0.originalTitle.lowercased().contains(lowercased)
            }
    }

    // MARK: - Private Helpers

    private func mapDocument(_ doc: DocumentSnapshot) throws -> Movie {
        guard let data = doc.data() else {
            throw FirestoreRepositoryError.invalidData(docId: doc.documentID)
        }

        // Thủ công map Firestore data → Movie struct
        // (vì Movie dùng URL?, Date, Decimal, nested enum — không thể Codable thuần)
        return try FirestoreMovieMapper.map(id: doc.documentID, data: data)
    }
}

// MARK: - Firestore Movie Mapper

enum FirestoreMovieMapper {
    static func map(id: String, data: [String: Any]) throws -> Movie {
        guard let title = data["title"] as? String else {
            throw FirestoreRepositoryError.missingField("title")
        }

        let originalTitle = data["originalTitle"] as? String ?? title
        let synopsis = data["synopsis"] as? String ?? ""
        let duration = data["duration"] as? Int ?? 0
        let rating = data["rating"] as? Double ?? 0.0
        let director = data["director"] as? String ?? ""
        let genre = data["genre"] as? [String] ?? []
        let cast = data["cast"] as? [String] ?? []
        let ageRatingRaw = data["ageRating"] as? String ?? "P"
        let ageRating = Movie.AgeRating(rawValue: ageRatingRaw) ?? .general

        // Date từ Firestore Timestamp
        let releaseDate: Date
        if let timestamp = data["releaseDate"] as? Timestamp {
            releaseDate = timestamp.dateValue()
        } else {
            releaseDate = Date()
        }

        // URLs
        let posterURL = (data["posterURL"] as? String).flatMap { URL(string: $0) }
        let backdropURL = (data["backdropURL"] as? String).flatMap { URL(string: $0) }
        let trailerURL = (data["trailerURL"] as? String).flatMap { URL(string: $0) }

        return Movie(
            id: id,
            title: title,
            originalTitle: originalTitle,
            posterURL: posterURL,
            backdropURL: backdropURL,
            synopsis: synopsis,
            duration: duration,
            rating: rating,
            genre: genre,
            releaseDate: releaseDate,
            ageRating: ageRating,
            trailerURL: trailerURL,
            cast: cast,
            director: director,
            isNowPlaying: true
        )
    }

    /// Chuyển Movie thành dictionary để seed lên Firestore
    static func toFirestore(_ movie: Movie, isNowPlaying: Bool) -> [String: Any] {
        var dict: [String: Any] = [
            "title": movie.title,
            "originalTitle": movie.originalTitle,
            "synopsis": movie.synopsis,
            "duration": movie.duration,
            "rating": movie.rating,
            "genre": movie.genre,
            "cast": movie.cast,
            "director": movie.director,
            "ageRating": movie.ageRating.rawValue,
            "releaseDate": Timestamp(date: movie.releaseDate),
            "isNowPlaying": isNowPlaying,
        ]
        if let url = movie.posterURL { dict["posterURL"] = url.absoluteString }
        if let url = movie.backdropURL { dict["backdropURL"] = url.absoluteString }
        if let url = movie.trailerURL { dict["trailerURL"] = url.absoluteString }
        return dict
    }
}

// MARK: - Errors

enum FirestoreRepositoryError: LocalizedError {
    case documentNotFound(id: String)
    case invalidData(docId: String)
    case missingField(_ field: String)

    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Không tìm thấy tài liệu với ID: \(id)"
        case .invalidData(let id):
            return "Dữ liệu không hợp lệ trong tài liệu: \(id)"
        case .missingField(let field):
            return "Thiếu trường bắt buộc: \(field)"
        }
    }
}

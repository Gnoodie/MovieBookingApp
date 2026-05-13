import Foundation
import FirebaseFirestore

// MARK: - FnBRepositoryProtocol

protocol FnBRepositoryProtocol {
    func fetchFnBItems() async throws -> [FnBItem]
}

// MARK: - FirestoreFnBRepository

/// Lấy danh sách F&B từ Firestore collection "fnb_items"
final class FirestoreFnBRepository: FnBRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "fnb_items"

    func fetchFnBItems() async throws -> [FnBItem] {
        let snapshot = try await db.collection(collection)
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "category")
            .order(by: "price")
            .getDocuments()

        return snapshot.documents.compactMap { mapFnBItem($0) }
    }

    // MARK: - Private

    private func mapFnBItem(_ doc: DocumentSnapshot) -> FnBItem? {
        guard let data = doc.data(),
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let priceRaw = data["price"] as? Double,
              let categoryRaw = data["category"] as? String,
              let category = FnBCategory(rawValue: categoryRaw) else {
            return nil
        }

        let imageURL = (data["imageURL"] as? String).flatMap { URL(string: $0) }
        let isAvailable = data["isAvailable"] as? Bool ?? true

        return FnBItem(
            id: doc.documentID,
            name: name,
            description: description,
            price: Decimal(priceRaw),
            imageURL: imageURL,
            category: category,
            isAvailable: isAvailable
        )
    }
}

// MARK: - MockFnBRepository

/// Dùng cho Preview / Unit Test
struct MockFnBRepository: FnBRepositoryProtocol {
    func fetchFnBItems() async throws -> [FnBItem] {
        return FnBItem.mocks
    }
}

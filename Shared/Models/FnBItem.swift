import Foundation

// MARK: - FnBCategory

enum FnBCategory: String, Codable, CaseIterable {
    case popcorn = "popcorn"
    case drink   = "drink"
    case combo   = "combo"

    var displayName: String {
        switch self {
        case .popcorn: return "Bắp rang"
        case .drink:   return "Thức uống"
        case .combo:   return "Combo"
        }
    }

    var icon: String {
        switch self {
        case .popcorn: return "🍿"
        case .drink:   return "🥤"
        case .combo:   return "🎁"
        }
    }
}

// MARK: - FnBItem

/// Sản phẩm F&B hiển thị trong menu
struct FnBItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let imageURL: URL?
    let category: FnBCategory
    let isAvailable: Bool

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let number = NSDecimalNumber(decimal: price)
        return (formatter.string(from: number) ?? "\(price)") + "đ"
    }
}

// MARK: - FnBOrderItem

/// Item đã được thêm vào giỏ hàng (có quantity)
struct FnBOrderItem: Codable, Equatable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
        hasher.combine(quantity)
    }


    let itemId: String
    let name: String
    let quantity: Int
    let unitPrice: Decimal

    var totalPrice: Decimal {
        unitPrice * Decimal(quantity)
    }

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let number = NSDecimalNumber(decimal: totalPrice)
        return (formatter.string(from: number) ?? "\(totalPrice)") + "đ"
    }
}

// MARK: - Mock Data

extension FnBItem {
    static let mocks: [FnBItem] = [
        FnBItem(
            id: "fnb-001",
            name: "Bắp rang bơ nhỏ (S)",
            description: "Bắp rang bơ thơm giòn cỡ nhỏ",
            price: 45_000,
            imageURL: nil,
            category: .popcorn,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-002",
            name: "Bắp rang bơ lớn (L)",
            description: "Bắp rang bơ thơm giòn cỡ lớn",
            price: 65_000,
            imageURL: nil,
            category: .popcorn,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-003",
            name: "Bắp phô mai (L)",
            description: "Bắp rang phủ phô mai cheddar",
            price: 75_000,
            imageURL: nil,
            category: .popcorn,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-004",
            name: "Coca Cola",
            description: "Nước ngọt Coca Cola lạnh",
            price: 30_000,
            imageURL: nil,
            category: .drink,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-005",
            name: "Pepsi",
            description: "Nước ngọt Pepsi lạnh",
            price: 30_000,
            imageURL: nil,
            category: .drink,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-006",
            name: "Nước suối Aquafina",
            description: "Nước suối tinh khiết 500ml",
            price: 20_000,
            imageURL: nil,
            category: .drink,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-007",
            name: "Combo Couple 💑",
            description: "2 Bắp lớn + 2 Coca Cola",
            price: 150_000,
            imageURL: nil,
            category: .combo,
            isAvailable: true
        ),
        FnBItem(
            id: "fnb-008",
            name: "Combo Gia Đình 👨‍👩‍👧‍👦",
            description: "3 Bắp lớn + 4 Nước suối",
            price: 250_000,
            imageURL: nil,
            category: .combo,
            isAvailable: true
        ),
    ]
}

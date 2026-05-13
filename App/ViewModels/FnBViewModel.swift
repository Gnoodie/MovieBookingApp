import Foundation

// MARK: - FnBViewModel

@MainActor
final class FnBViewModel: ObservableObject {

    // MARK: - Published State

    @Published var fnbItems: [FnBItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedCategory: FnBCategory = .popcorn

    /// Dictionary [itemId: quantity] — giỏ hàng F&B
    @Published var cart: [String: Int] = [:]

    // MARK: - Input (từ SeatMap)

    let selectedSeats: [Seat]
    let showtime: Showtime
    let movie: Movie

    // MARK: - Dependencies

    private let repository: FnBRepositoryProtocol

    // MARK: - Init

    init(
        selectedSeats: [Seat],
        showtime: Showtime,
        movie: Movie,
        repository: FnBRepositoryProtocol = FirestoreFnBRepository()
    ) {
        self.selectedSeats = selectedSeats
        self.showtime = showtime
        self.movie = movie
        self.repository = repository
    }

    // MARK: - Computed

    /// Items theo category đang chọn
    var filteredItems: [FnBItem] {
        fnbItems.filter { $0.category == selectedCategory && $0.isAvailable }
    }

    /// Tất cả items đã thêm vào giỏ (có quantity > 0)
    var cartItems: [FnBOrderItem] {
        cart.compactMap { (itemId, quantity) -> FnBOrderItem? in
            guard quantity > 0,
                  let item = fnbItems.first(where: { $0.id == itemId }) else { return nil }
            return FnBOrderItem(
                itemId: item.id,
                name: item.name,
                quantity: quantity,
                unitPrice: item.price
            )
        }
        .sorted { $0.name < $1.name }
    }

    /// Tổng số lượng item trong giỏ
    var totalQuantity: Int {
        cart.values.reduce(0, +)
    }

    /// Tổng tiền F&B
    var totalFnB: Decimal {
        cartItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }

    /// Tổng tiền F&B đã format
    var formattedTotalFnB: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let number = NSDecimalNumber(decimal: totalFnB)
        return (formatter.string(from: number) ?? "0") + "đ"
    }

    /// Số lượng của một item cụ thể trong giỏ
    func quantity(for itemId: String) -> Int {
        cart[itemId] ?? 0
    }

    // MARK: - Actions

    func onAppear() {
        guard fnbItems.isEmpty else { return }
        loadItems()
    }

    func selectCategory(_ category: FnBCategory) {
        selectedCategory = category
    }

    func increaseQuantity(for item: FnBItem) {
        let current = cart[item.id] ?? 0
        cart[item.id] = current + 1
    }

    func decreaseQuantity(for item: FnBItem) {
        let current = cart[item.id] ?? 0
        if current > 0 {
            cart[item.id] = current - 1
        }
        if cart[item.id] == 0 {
            cart.removeValue(forKey: item.id)
        }
    }

    func clearCart() {
        cart = [:]
    }

    // MARK: - Private

    private func loadItems() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                fnbItems = try await repository.fetchFnBItems()
                // Nếu không có popcorn thì chọn category đầu tiên
                if !fnbItems.contains(where: { $0.category == selectedCategory }) {
                    selectedCategory = fnbItems.first?.category ?? .combo
                }
            } catch {
                // Fallback về mock data để không block luồng mua vé
                fnbItems = FnBItem.mocks
                errorMessage = nil // Không hiện lỗi — silently fallback
            }
            isLoading = false
        }
    }
}

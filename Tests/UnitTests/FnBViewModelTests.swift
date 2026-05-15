import XCTest
@testable import MovieBookingApp

// MARK: - FnBViewModel Tests

@MainActor
final class FnBViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private func makeShowtime() -> Showtime {
        Showtime(
            id: "show-test",
            movieId: "movie-test",
            cinemaId: "cinema-test",
            hallId: "hall-test",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200),
            language: .vietnamese,
            subtitleLanguage: nil,
            format: .twoD,
            basePrice: 150_000,
            availableSeats: 50,
            totalSeats: 120
        )
    }

    private func makeMovie() -> Movie {
        Movie(
            id: "movie-test",
            title: "Test Movie",
            originalTitle: "Test Movie",
            overview: "A test movie",
            posterURL: nil,
            backdropURL: nil,
            trailerURL: nil,
            releaseDate: Date(),
            runtime: 120,
            genres: ["Action"],
            cast: [],
            director: "Director",
            ageRating: .teens13,
            imdbScore: 7.5,
            language: "VI",
            isNowPlaying: true,
            isComingSoon: false
        )
    }

    private func makeSeat() -> Seat {
        Seat(id: "E7", row: "E", number: 7, type: .standard, status: .available, priceMultiplier: 1.0)
    }

    private func makeViewModel(items: [FnBItem] = FnBItem.mocks) -> FnBViewModel {
        FnBViewModel(
            selectedSeats: [makeSeat()],
            showtime: makeShowtime(),
            movie: makeMovie(),
            repository: MockFnBRepository(items: items)
        )
    }

    // MARK: - Initial State Tests

    func test_initialState_cartIsEmpty() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.cart.isEmpty)
        XCTAssertEqual(vm.totalQuantity, 0)
        XCTAssertEqual(vm.totalFnB, 0)
    }

    func test_initialState_defaultCategoryIsPopcorn() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.selectedCategory, .popcorn)
    }

    // MARK: - Cart Operations

    func test_increaseQuantity_addsItemToCart() {
        let vm = makeViewModel()
        let item = FnBItem.mocks.first!
        vm.increaseQuantity(for: item)

        XCTAssertEqual(vm.cart[item.id], 1)
    }

    func test_increaseQuantity_multipleTimesAccumulates() {
        let vm = makeViewModel()
        let item = FnBItem.mocks.first!
        vm.increaseQuantity(for: item)
        vm.increaseQuantity(for: item)
        vm.increaseQuantity(for: item)

        XCTAssertEqual(vm.cart[item.id], 3)
    }

    func test_decreaseQuantity_reducesCount() {
        let vm = makeViewModel()
        let item = FnBItem.mocks.first!
        vm.increaseQuantity(for: item)
        vm.increaseQuantity(for: item)
        vm.decreaseQuantity(for: item)

        XCTAssertEqual(vm.cart[item.id], 1)
    }

    func test_decreaseQuantity_removesItemWhenZero() {
        let vm = makeViewModel()
        let item = FnBItem.mocks.first!
        vm.increaseQuantity(for: item)
        vm.decreaseQuantity(for: item) // quantity → 0 → item removed from cart

        XCTAssertNil(vm.cart[item.id])
    }

    func test_decreaseQuantity_doesNotGoNegative() {
        let vm = makeViewModel()
        let item = FnBItem.mocks.first!
        // Giảm khi chưa có trong giỏ
        vm.decreaseQuantity(for: item)

        XCTAssertNil(vm.cart[item.id])
        XCTAssertEqual(vm.totalQuantity, 0)
    }

    func test_clearCart_emptiesAllItems() {
        let vm = makeViewModel()
        FnBItem.mocks.forEach { vm.increaseQuantity(for: $0) }
        XCTAssertFalse(vm.cart.isEmpty)

        vm.clearCart()
        XCTAssertTrue(vm.cart.isEmpty)
        XCTAssertEqual(vm.totalQuantity, 0)
    }

    // MARK: - Computed Properties

    func test_totalQuantity_sumOfAllItems() {
        let vm = makeViewModel()
        let popcorn = FnBItem.mocks.first { $0.category == .popcorn }!
        let drink   = FnBItem.mocks.first { $0.category == .drink }!

        vm.increaseQuantity(for: popcorn)
        vm.increaseQuantity(for: popcorn)
        vm.increaseQuantity(for: drink)

        XCTAssertEqual(vm.totalQuantity, 3)
    }

    func test_totalFnB_correctCalculation() {
        let vm = makeViewModel()
        // Bắp nhỏ: 45_000 × 2 = 90_000
        // Coca Cola: 30_000 × 1 = 30_000
        // Total: 120_000
        let popcorn = FnBItem.mocks.first { $0.id == "fnb-001" }!
        let cola    = FnBItem.mocks.first { $0.id == "fnb-004" }!

        vm.increaseQuantity(for: popcorn)
        vm.increaseQuantity(for: popcorn)
        vm.increaseQuantity(for: cola)

        XCTAssertEqual(vm.totalFnB, 120_000)
    }

    func test_cartItems_onlyContainsPositiveQuantity() {
        let vm = makeViewModel()
        let item1 = FnBItem.mocks[0]
        let item2 = FnBItem.mocks[1]

        vm.increaseQuantity(for: item1)
        vm.increaseQuantity(for: item2)
        vm.decreaseQuantity(for: item2) // item2 quantity → 0 → removed

        XCTAssertEqual(vm.cartItems.count, 1)
        XCTAssertEqual(vm.cartItems.first?.itemId, item1.id)
    }

    func test_quantity_returnsZeroForUnknownItem() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.quantity(for: "non-existent-id"), 0)
    }

    // MARK: - Category Filter

    func test_selectCategory_changesFilter() {
        let vm = makeViewModel()
        vm.selectCategory(.drink)
        XCTAssertEqual(vm.selectedCategory, .drink)
    }

    func test_filteredItems_onlyShowsSelectedCategory() {
        let vm = makeViewModel()
        vm.fnbItems = FnBItem.mocks
        vm.selectCategory(.drink)

        let result = vm.filteredItems
        XCTAssertTrue(result.allSatisfy { $0.category == .drink })
    }

    func test_filteredItems_excludesUnavailable() {
        let unavailableItem = FnBItem(
            id: "fnb-unavail",
            name: "Hết hàng",
            description: "",
            price: 0,
            imageURL: nil,
            category: .popcorn,
            isAvailable: false
        )
        let vm = makeViewModel(items: FnBItem.mocks + [unavailableItem])
        vm.fnbItems = FnBItem.mocks + [unavailableItem]
        vm.selectCategory(.popcorn)

        XCTAssertFalse(vm.filteredItems.contains { $0.id == "fnb-unavail" })
    }

    // MARK: - Load Items (async)

    func test_onAppear_loadsItems() async throws {
        let vm = makeViewModel()
        vm.onAppear()

        // Chờ async load
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        XCTAssertFalse(vm.fnbItems.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func test_onAppear_doesNotReloadIfAlreadyLoaded() async throws {
        let mockRepo = MockFnBRepository(items: FnBItem.mocks, callCount: 0)
        let vm = FnBViewModel(
            selectedSeats: [],
            showtime: makeShowtime(),
            movie: makeMovie(),
            repository: mockRepo
        )
        vm.fnbItems = FnBItem.mocks // Đã có data
        vm.onAppear()

        XCTAssertEqual(mockRepo.fetchCallCount, 0)
    }
}

// MARK: - MockFnBRepository

private final class MockFnBRepository: FnBRepositoryProtocol {
    private let items: [FnBItem]
    var fetchCallCount: Int = 0

    init(items: [FnBItem], callCount: Int = 0) {
        self.items = items
        self.fetchCallCount = callCount
    }

    func fetchFnBItems() async throws -> [FnBItem] {
        fetchCallCount += 1
        return items
    }
}

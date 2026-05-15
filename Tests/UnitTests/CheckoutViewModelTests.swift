import XCTest
@testable import MovieBookingApp

// MARK: - CheckoutViewModel Tests

@MainActor
final class CheckoutViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private func makeShowtime(format: Showtime.Format = .twoD, basePrice: Decimal = 150_000) -> Showtime {
        Showtime(
            id: "show-test",
            movieId: "movie-test",
            cinemaId: "cinema-test",
            hallId: "hall-test",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200),
            language: .vietnamese,
            subtitleLanguage: nil,
            format: format,
            basePrice: basePrice,
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

    private func makeSeat(
        row: String = "E",
        number: Int = 7,
        type: Seat.SeatType = .standard,
        priceMultiplier: Double = 1.0
    ) -> Seat {
        Seat(
            id: "\(row)\(number)",
            row: row,
            number: number,
            type: type,
            status: .available,
            priceMultiplier: priceMultiplier
        )
    }

    private func makeViewModel(
        seats: [Seat] = [],
        showtime: Showtime? = nil,
        fnbItems: [FnBOrderItem] = []
    ) -> CheckoutViewModel {
        CheckoutViewModel(
            selectedSeats: seats,
            showtime: showtime ?? makeShowtime(),
            movie: makeMovie(),
            fnbItems: fnbItems,
            orderRepository: MockOrderRepository(),
            paymentService: .shared
        )
    }

    // MARK: - Price Calculation Tests

    func test_subtotalTicket_singleStandardSeat() {
        let seat = makeSeat(priceMultiplier: 1.0)
        let vm = makeViewModel(seats: [seat], showtime: makeShowtime(basePrice: 150_000))

        XCTAssertEqual(vm.subtotalTicket, 150_000)
    }

    func test_subtotalTicket_vipSeatMultiplier() {
        let vipSeat = makeSeat(type: .vip, priceMultiplier: 1.5)
        let vm = makeViewModel(seats: [vipSeat], showtime: makeShowtime(basePrice: 100_000))

        // VIP: 100_000 × 1.5 = 150_000
        XCTAssertEqual(vm.subtotalTicket, 150_000)
    }

    func test_subtotalTicket_multipleSeats() {
        let seats = [
            makeSeat(row: "E", number: 7, priceMultiplier: 1.0),   // 150_000
            makeSeat(row: "E", number: 8, priceMultiplier: 1.0),   // 150_000
            makeSeat(row: "A", number: 1, priceMultiplier: 1.5),   // 225_000
        ]
        let vm = makeViewModel(seats: seats, showtime: makeShowtime(basePrice: 150_000))

        XCTAssertEqual(vm.subtotalTicket, 525_000)
    }

    func test_formatSurcharge_imax_perSeat() {
        let seats = [makeSeat(), makeSeat(number: 8)]
        let vm = makeViewModel(seats: seats, showtime: makeShowtime(format: .imax))

        // IMAX surcharge: 60_000 × 2 ghế = 120_000
        XCTAssertEqual(vm.formatSurcharge, 120_000)
    }

    func test_formatSurcharge_twoD_isZero() {
        let vm = makeViewModel(seats: [makeSeat()], showtime: makeShowtime(format: .twoD))
        XCTAssertEqual(vm.formatSurcharge, 0)
    }

    func test_subtotalFnB_sumOfItems() {
        let fnbItems: [FnBOrderItem] = [
            FnBOrderItem(itemId: "fnb-001", name: "Bắp nhỏ", quantity: 2, unitPrice: 45_000),  // 90_000
            FnBOrderItem(itemId: "fnb-004", name: "Coca Cola", quantity: 1, unitPrice: 30_000), // 30_000
        ]
        let vm = makeViewModel(fnbItems: fnbItems)

        XCTAssertEqual(vm.subtotalFnB, 120_000)
    }

    func test_totalAfterDiscount_withDiscount() {
        let seat = makeSeat(priceMultiplier: 1.0) // 150_000
        let vm = makeViewModel(seats: [seat], showtime: makeShowtime(format: .twoD, basePrice: 150_000))

        vm.voucherCode = "WELCOME50"
        vm.applyVoucher()

        // 150_000 - 50_000 = 100_000
        XCTAssertEqual(vm.totalAfterDiscount, 100_000)
    }

    func test_totalAfterDiscount_cannotGoNegative() {
        let seat = makeSeat(priceMultiplier: 1.0) // 150_000
        let vm = makeViewModel(seats: [seat], showtime: makeShowtime(format: .twoD, basePrice: 150_000))

        // Giả lập discount lớn hơn total
        vm.discountAmount = 999_999

        XCTAssertEqual(vm.totalAfterDiscount, 0)
    }

    // MARK: - Voucher Tests

    func test_applyVoucher_WELCOME50_success() {
        let vm = makeViewModel(seats: [makeSeat()])
        vm.voucherCode = "WELCOME50"
        vm.applyVoucher()

        XCTAssertTrue(vm.voucherApplied)
        XCTAssertEqual(vm.discountAmount, 50_000)
        XCTAssertNil(vm.voucherError)
    }

    func test_applyVoucher_MOVIE20_percentDiscount() {
        // 150_000 tổng, MOVIE20 = giảm 20%
        let seat = makeSeat(priceMultiplier: 1.0)
        let vm = makeViewModel(seats: [seat], showtime: makeShowtime(format: .twoD, basePrice: 150_000))
        vm.voucherCode = "MOVIE20"
        vm.applyVoucher()

        XCTAssertTrue(vm.voucherApplied)
        XCTAssertEqual(vm.discountAmount, 30_000) // 150_000 × 20%
    }

    func test_applyVoucher_invalidCode_setsError() {
        let vm = makeViewModel()
        vm.voucherCode = "INVALID_CODE"
        vm.applyVoucher()

        XCTAssertFalse(vm.voucherApplied)
        XCTAssertNotNil(vm.voucherError)
        XCTAssertEqual(vm.discountAmount, 0)
    }

    func test_applyVoucher_emptyCode_setsError() {
        let vm = makeViewModel()
        vm.voucherCode = ""
        vm.applyVoucher()

        XCTAssertFalse(vm.voucherApplied)
        XCTAssertNotNil(vm.voucherError)
    }

    func test_applyVoucher_alreadyApplied_setsError() {
        let vm = makeViewModel()
        vm.voucherCode = "WELCOME50"
        vm.applyVoucher()

        // Thử apply lần 2
        vm.applyVoucher()
        XCTAssertNotNil(vm.voucherError)
        XCTAssertEqual(vm.discountAmount, 50_000) // Không thay đổi
    }

    func test_removeVoucher_resetsState() {
        let vm = makeViewModel()
        vm.voucherCode = "WELCOME50"
        vm.applyVoucher()
        vm.removeVoucher()

        XCTAssertFalse(vm.voucherApplied)
        XCTAssertEqual(vm.discountAmount, 0)
        XCTAssertEqual(vm.voucherCode, "")
        XCTAssertNil(vm.voucherError)
    }

    func test_applyVoucher_caseInsensitive() {
        let vm = makeViewModel()
        vm.voucherCode = "welcome50" // lowercase
        vm.applyVoucher()

        XCTAssertTrue(vm.voucherApplied)
        XCTAssertEqual(vm.discountAmount, 50_000)
    }

    // MARK: - Payment Method Tests

    func test_selectPaymentMethod_momo_succeeds() {
        let vm = makeViewModel()
        vm.selectPaymentMethod(.momo)
        XCTAssertEqual(vm.selectedPaymentMethod, .momo)
    }

    func test_selectPaymentMethod_applePay_blocked() {
        let vm = makeViewModel()
        vm.selectedPaymentMethod = .momo
        vm.selectPaymentMethod(.applePay) // Apple Pay không available

        XCTAssertEqual(vm.selectedPaymentMethod, .momo) // Không thay đổi
    }

    // MARK: - canPay Tests

    func test_canPay_true_whenSeatsAndMethodAvailable() {
        let vm = makeViewModel(seats: [makeSeat()])
        vm.selectedPaymentMethod = .mockPay
        XCTAssertTrue(vm.canPay)
    }

    func test_canPay_false_whenNoSeats() {
        let vm = makeViewModel(seats: [])
        XCTAssertFalse(vm.canPay)
    }

    func test_canPay_false_whenProcessing() {
        let vm = makeViewModel(seats: [makeSeat()])
        vm.isProcessingPayment = true
        XCTAssertFalse(vm.canPay)
    }

    // MARK: - Display Tests

    func test_seatLabels_multipleSeats() {
        let seats = [
            makeSeat(row: "E", number: 7),
            makeSeat(row: "E", number: 8),
        ]
        let vm = makeViewModel(seats: seats)
        XCTAssertEqual(vm.seatLabels, "E7, E8")
    }

    func test_hasFnB_true_whenItemsPresent() {
        let fnbItems = [FnBOrderItem(itemId: "fnb-001", name: "Bắp", quantity: 1, unitPrice: 45_000)]
        let vm = makeViewModel(fnbItems: fnbItems)
        XCTAssertTrue(vm.hasFnB)
    }

    func test_hasFnB_false_whenEmpty() {
        let vm = makeViewModel(fnbItems: [])
        XCTAssertFalse(vm.hasFnB)
    }

    func test_formatVND_correctFormat() {
        let result = CheckoutViewModel.formatVND(495_000)
        XCTAssertEqual(result, "495.000đ")
    }

    func test_formatVND_zero() {
        let result = CheckoutViewModel.formatVND(0)
        XCTAssertEqual(result, "0đ")
    }
}

// MARK: - MockOrderRepository

private final class MockOrderRepository: OrderRepositoryProtocol {
    func createOrder(
        seats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem],
        discountAmount: Decimal,
        paymentMethod: PaymentMethod,
        paymentReference: String?
    ) async throws -> (order: Order, ticket: Ticket) {
        let order = Order(
            id: "mock-order-001",
            userId: "mock-user",
            movieId: movie.id,
            movieTitle: movie.title,
            moviePosterURL: nil,
            cinemaName: "Mock Cinema",
            hallName: "Mock Hall",
            showtime: showtime.startTime,
            format: showtime.format.rawValue,
            seats: seats.map { BookedSeatInfo(row: $0.row, number: $0.number, type: $0.type.rawValue, price: $0.price(basePrice: showtime.basePrice)) },
            fnbItems: fnbItems,
            subtotalTicket: 150_000,
            subtotalFnB: 0,
            formatSurcharge: 0,
            discountAmount: discountAmount,
            totalAmount: 150_000 - discountAmount,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference,
            status: .paid,
            createdAt: Date()
        )
        let ticket = Ticket(
            id: "mock-ticket-001",
            bookingId: "MOCK001",
            movieTitle: movie.title,
            moviePosterURL: nil,
            cinemaName: "Mock Cinema",
            cinemaAddress: "",
            hallName: "Mock Hall",
            showtime: showtime.startTime,
            format: showtime.format.rawValue,
            language: showtime.language.rawValue,
            seats: seats.map { Ticket.BookedSeat(row: $0.row, number: $0.number, type: $0.type.rawValue, price: $0.price(basePrice: showtime.basePrice)) },
            totalAmount: 150_000,
            status: .active,
            purchasedAt: Date(),
            qrCodeData: "MBK|MOCK001|show-test|E7|12345",
            expiresAt: nil
        )
        return (order, ticket)
    }

    func fetchMyOrders() async throws -> [Order] { [] }
    func fetchOrderDetail(id: String) async throws -> Order { throw NSError(domain: "Mock", code: 404) }
}

import XCTest
@testable import MovieBookingApp

// MARK: - ETicketViewModel Tests

@MainActor
final class ETicketViewModelTests: XCTestCase {

    private func makeTicket(bookingId: String = "ABC123DEF") -> Ticket {
        Ticket(
            id: UUID().uuidString,
            bookingId: bookingId,
            movieTitle: "Người Nhện: Vũ Trụ Mới",
            moviePosterURL: nil,
            cinemaName: "CGV Vincom",
            cinemaAddress: "191 Bà Triệu, Hà Nội",
            hallName: "Phòng 1 - IMAX",
            showtime: Date().addingTimeInterval(3600),
            format: "IMAX",
            language: "EN",
            seats: [
                Ticket.BookedSeat(row: "E", number: 7, type: "Standard", price: 150_000),
                Ticket.BookedSeat(row: "E", number: 8, type: "Standard", price: 150_000),
            ],
            totalAmount: 300_000,
            status: .active,
            purchasedAt: Date(),
            qrCodeData: "MBK|ABC123DEF|show-001|E7,E8|1234567890",
            expiresAt: nil
        )
    }

    // MARK: - QR Generation

    func test_qrCode_generatedOnInit() async throws {
        let vm = ETicketViewModel(ticket: makeTicket())

        // Chờ async generation hoàn thành
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        XCTAssertNotNil(vm.qrImage, "QR image should be generated on init")
    }

    func test_qrCode_notNilForValidBookingId() async throws {
        let vm = ETicketViewModel(ticket: makeTicket(bookingId: "VALID-BOOKING-ID"))
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(vm.qrImage)
    }

    func test_qrCode_fallbackForEmptyBookingId() async throws {
        // bookingId rỗng → dùng fallback string "MBK-TICKET"
        let vm = ETicketViewModel(ticket: makeTicket(bookingId: ""))
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(vm.qrImage, "Should generate QR even with empty bookingId using fallback")
    }

    // MARK: - Screenshot Blur State

    func test_initialState_qrNotBlurred() {
        let vm = ETicketViewModel(ticket: makeTicket())
        XCTAssertFalse(vm.isQRBlurred)
    }

    // MARK: - Ticket Data Integrity

    func test_ticket_propertiesMatchInput() {
        let ticket = makeTicket(bookingId: "TEST-001")
        let vm = ETicketViewModel(ticket: ticket)

        XCTAssertEqual(vm.ticket.bookingId, "TEST-001")
        XCTAssertEqual(vm.ticket.movieTitle, "Người Nhện: Vũ Trụ Mới")
        XCTAssertEqual(vm.ticket.seats.count, 2)
        XCTAssertEqual(vm.ticket.totalAmount, 300_000)
    }

    func test_ticket_seatLabels() {
        let ticket = makeTicket()
        XCTAssertEqual(ticket.seatLabels, "E7, E8")
    }

    func test_ticket_displayBookingId_hasMBKPrefix() {
        let ticket = makeTicket(bookingId: "ABC123")
        XCTAssertTrue(ticket.displayBookingId.hasPrefix("MBK-"))
    }

    func test_ticket_isActive() {
        let ticket = makeTicket()
        XCTAssertTrue(ticket.isActive)
    }

    func test_ticket_ticketCount() {
        let ticket = makeTicket()
        XCTAssertEqual(ticket.ticketCount, 2)
    }
}

// MARK: - MyTicketsViewModel Tests

@MainActor
final class MyTicketsViewModelTests: XCTestCase {

    private func makeTicket(
        bookingId: String,
        status: Ticket.TicketStatus,
        showtimeDayOffset: Int
    ) -> Ticket {
        let showtime = Calendar.current.date(byAdding: .day, value: showtimeDayOffset, to: Date()) ?? Date()
        return Ticket(
            id: UUID().uuidString,
            bookingId: bookingId,
            movieTitle: "Test Movie",
            moviePosterURL: nil,
            cinemaName: "Test Cinema",
            cinemaAddress: "",
            hallName: "Test Hall",
            showtime: showtime,
            format: "2D",
            language: "VI",
            seats: [Ticket.BookedSeat(row: "A", number: 1, type: "Standard", price: 90_000)],
            totalAmount: 90_000,
            status: status,
            purchasedAt: Date(),
            qrCodeData: "MBK|\(bookingId)|show-001|A1|12345",
            expiresAt: nil
        )
    }

    func test_fetchTickets_separatesActiveAndHistory() async {
        let futureTicket  = makeTicket(bookingId: "FUTURE", status: .active, showtimeDayOffset: +1)
        let pastTicket    = makeTicket(bookingId: "PAST",   status: .used,   showtimeDayOffset: -5)

        let vm = MyTicketsViewModel(
            ticketRepository: MockTicketRepository(tickets: [futureTicket, pastTicket])
        )

        await vm.fetchTickets()

        XCTAssertEqual(vm.activeTickets.count, 1)
        XCTAssertEqual(vm.activeTickets.first?.bookingId, "FUTURE")
        XCTAssertEqual(vm.historyTickets.count, 1)
        XCTAssertEqual(vm.historyTickets.first?.bookingId, "PAST")
    }

    func test_fetchTickets_activeTicketsSortedAscending() async {
        let soon  = makeTicket(bookingId: "SOON",  status: .active, showtimeDayOffset: +1)
        let later = makeTicket(bookingId: "LATER", status: .active, showtimeDayOffset: +5)

        let vm = MyTicketsViewModel(
            ticketRepository: MockTicketRepository(tickets: [later, soon])
        )

        await vm.fetchTickets()

        // Sắp xếp tăng dần — vé gần nhất hiện trước
        XCTAssertEqual(vm.activeTickets.first?.bookingId, "SOON")
    }

    func test_fetchTickets_emptyRepo_noError() async {
        let vm = MyTicketsViewModel(
            ticketRepository: MockTicketRepository(tickets: [])
        )

        await vm.fetchTickets()

        XCTAssertTrue(vm.activeTickets.isEmpty)
        XCTAssertTrue(vm.historyTickets.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }

    func test_fetchTickets_repoError_setsErrorMessage() async {
        let vm = MyTicketsViewModel(
            ticketRepository: FailingTicketRepository()
        )

        await vm.fetchTickets()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.activeTickets.isEmpty)
    }

    func test_isLoading_falseAfterFetch() async {
        let vm = MyTicketsViewModel(
            ticketRepository: MockTicketRepository(tickets: [])
        )

        await vm.fetchTickets()

        XCTAssertFalse(vm.isLoading)
    }
}

// MARK: - MockTicketRepository

private final class MockTicketRepository: TicketRepositoryProtocol {
    private let tickets: [Ticket]
    init(tickets: [Ticket]) { self.tickets = tickets }

    func fetchMyTickets() async throws -> [Ticket] { tickets }
    func fetchTicketDetail(id: String) async throws -> Ticket {
        guard let ticket = tickets.first(where: { $0.id == id }) else {
            throw NSError(domain: "Mock", code: 404)
        }
        return ticket
    }
}

private final class FailingTicketRepository: TicketRepositoryProtocol {
    func fetchMyTickets() async throws -> [Ticket] {
        throw NSError(domain: "NetworkError", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "Lỗi kết nối mạng"
        ])
    }
    func fetchTicketDetail(id: String) async throws -> Ticket {
        throw NSError(domain: "NetworkError", code: 500)
    }
}

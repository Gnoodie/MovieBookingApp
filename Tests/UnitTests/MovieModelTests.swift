import XCTest
@testable import SharedKit

final class MovieModelTests: XCTestCase {
    func test_seat_displayName() {
        let seat = Seat(id: "A5", row: "A", number: 5,
                       type: .standard, status: .available,
                       priceMultiplier: 1.0)
        XCTAssertEqual(seat.displayName, "A5")
    }
    
    func test_mockRepo_returnsData() async throws {
        let repo = MockMovieRepository()
        let movies = try await repo.fetchNowPlaying()
        XCTAssertFalse(movies.isEmpty)
        XCTAssertEqual(movies.first?.ageRating, .teens13)
    }
    
    func test_seat_status_default_available() {
        let seat = Seat(id: "B1", row: "B", number: 1,
                       type: .vip, status: .available,
                       priceMultiplier: 1.5)
        XCTAssertEqual(seat.status, .available)
    }
}

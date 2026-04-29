import Foundation

// MARK: - Seat Repository Protocol

protocol SeatRepositoryProtocol {
    func fetchSeats(showtimeId: String) async throws -> [Seat]
    func holdSeats(showtimeId: String, seatIds: [String]) async throws -> HoldResponse
    func releaseSeats(holdId: String) async throws
}

struct HoldResponse: Codable {
    let holdId: String
    let expiresAt: Date
    let seatIds: [String]
}

// MARK: - Mock Implementation

struct MockSeatRepository: SeatRepositoryProtocol {
    func fetchSeats(showtimeId: String) async throws -> [Seat] {
        return SeatMap.mock(showtimeId: showtimeId).seats
    }
    
    func holdSeats(showtimeId: String, seatIds: [String]) async throws -> HoldResponse {
        // Giả lập hold ghế trong 10 phút
        let expiresAt = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        return HoldResponse(holdId: UUID().uuidString, expiresAt: expiresAt, seatIds: seatIds)
    }
    
    func releaseSeats(holdId: String) async throws {
        // Giả lập release ghế thành công
    }
}

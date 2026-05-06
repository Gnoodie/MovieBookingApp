import Foundation

// MARK: - Showtime Repository Protocol

protocol ShowtimeRepositoryProtocol {
    func fetchShowtimes(movieId: String, date: Date) async throws -> [Showtime]
    func fetchShowtimesByDate(movieId: String, cinemaId: String, date: Date) async throws -> [Showtime]
    func fetchCinemas() async throws -> [Cinema]
}

// MARK: - Mock Implementation

struct MockShowtimeRepository: ShowtimeRepositoryProtocol {
    func fetchShowtimes(movieId: String, date: Date) async throws -> [Showtime] {
        // Trả về mock showtimes cho tất cả rạp
        return Showtime.mocks(for: movieId, cinemaId: "cinema-001") +
               Showtime.mocks(for: movieId, cinemaId: "cinema-002")
    }

    func fetchShowtimesByDate(movieId: String, cinemaId: String, date: Date) async throws -> [Showtime] {
        return Showtime.mocks(for: movieId, cinemaId: cinemaId)
    }

    func fetchCinemas() async throws -> [Cinema] {
        return Cinema.mocks
    }
}

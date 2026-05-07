import Foundation
import Combine

@MainActor
final class ShowtimeViewModel: ObservableObject {
    @Published var movie: Movie
    @Published var availableDates: [Date] = []
    @Published var selectedDate: Date = Date() {
        didSet {
            showtimesByCinema = [:]
            loadShowtimes(for: selectedDate)
        }
    }
    
    @Published var cinemas: [Cinema] = []
    @Published var expandedCinemaId: String? = nil
    @Published var showtimesByCinema: [String: [Showtime]] = [:]
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    
    @Published var isLoadingCinemas: Bool = false
    @Published var isLoadingShowtimes: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var selectedShowtime: Showtime? = nil
    
    var sortedCinemas: [Cinema] {
        guard let lat = userLatitude, let lon = userLongitude else {
            return cinemas.sorted { $0.name < $1.name }
        }
        return cinemas.sorted {
            distanceKm(from: (lat, lon), to: ($0.latitude, $0.longitude)) <
            distanceKm(from: (lat, lon), to: ($1.latitude, $1.longitude))
        }
    }
    
    private let showtimeRepository: ShowtimeRepositoryProtocol
    
    init(movie: Movie, showtimeRepository: ShowtimeRepositoryProtocol = MockShowtimeRepository()) {
        self.movie = movie
        self.showtimeRepository = showtimeRepository
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.availableDates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    func onAppear() {
        loadCinemas()
        loadShowtimes(for: selectedDate)
    }
    
    func cinemaTapped(_ cinema: Cinema) {
        if expandedCinemaId == cinema.id {
            expandedCinemaId = nil
        } else {
            expandedCinemaId = cinema.id
        }
    }
    
    func showtimeTapped(_ showtime: Showtime) {
        selectedShowtime = showtime
    }
    
    private func loadCinemas() {
        isLoadingCinemas = true
        Task {
            do {
                let fetchedCinemas = try await showtimeRepository.fetchCinemas()
                self.cinemas = fetchedCinemas
                self.isLoadingCinemas = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingCinemas = false
            }
        }
    }
    
    private func loadShowtimes(for date: Date) {
        isLoadingShowtimes = true
        let movieId = movie.id
        
        Task {
            do {
                var grouped: [String: [Showtime]] = [:]
                let currentCinemas = self.cinemas
                
                try await withThrowingTaskGroup(of: (String, [Showtime]).self) { group in
                    for cinema in currentCinemas {
                        group.addTask {
                            let shows = try await self.showtimeRepository.fetchShowtimesByDate(
                                movieId: movieId,
                                cinemaId: cinema.id,
                                date: date
                            )
                            return (cinema.id, shows)
                        }
                    }
                    for try await (cinemaId, shows) in group {
                        grouped[cinemaId] = shows
                    }
                }
                self.showtimesByCinema = grouped
                self.isLoadingShowtimes = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingShowtimes = false
            }
        }
    }
    
    func locationUpdated(lat: Double, lon: Double) {
        userLatitude = lat
        userLongitude = lon
    }
    
    func locationDenied() {
        userLatitude = nil
        userLongitude = nil
    }
    
    private func distanceKm(from: (Double, Double), to: (Double, Double)) -> Double {
        let R = 6371.0
        let lat1 = from.0 * .pi / 180
        let lat2 = to.0   * .pi / 180
        let dLat = (to.0 - from.0) * .pi / 180
        let dLon = (to.1 - from.1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

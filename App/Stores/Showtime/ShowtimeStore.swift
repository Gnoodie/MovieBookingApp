import Foundation
import ComposableArchitecture

// MARK: - ShowtimeFeature (TCA Reducer)

@Reducer
struct ShowtimeFeature {

    // MARK: State

    @ObservableState
    struct State: Equatable {
        // Input từ navigation
        var movie: Movie

        // Date picker
        var availableDates: [Date] = []
        var selectedDate: Date = Date()

        // Cinema list
        var cinemas: [Cinema] = []
        var expandedCinemaId: String? = nil

        // Showtimes grouped by cinema
        var showtimesByCinema: [String: [Showtime]] = [:]

        // User's GPS location (lat, lon)
        var userLatitude: Double?
        var userLongitude: Double?

        // Loading & error
        var isLoadingCinemas: Bool   = false
        var isLoadingShowtimes: Bool = false
        var errorMessage: String?    = nil

        // Selected showtime → navigate to SeatMap
        var selectedShowtime: Showtime? = nil

        // Computed: Cinemas sorted by distance if GPS available
        var sortedCinemas: [Cinema] {
            guard let lat = userLatitude, let lon = userLongitude else {
                return cinemas.sorted { $0.name < $1.name }
            }
            return cinemas.sorted {
                distanceKm(from: (lat, lon), to: ($0.latitude, $0.longitude)) <
                distanceKm(from: (lat, lon), to: ($1.latitude, $1.longitude))
            }
        }

        init(movie: Movie) {
            self.movie = movie
            // Tạo 7 ngày tiếp theo
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            self.availableDates = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: today)
            }
        }

        // Haversine distance helper
        private func distanceKm(
            from: (Double, Double),
            to: (Double, Double)
        ) -> Double {
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

    // MARK: Action

    enum Action {
        // Lifecycle
        case onAppear
        case onDisappear

        // Date selection
        case dateSelected(Date)

        // Cinema interaction
        case cinemaTapped(Cinema)
        case cinemaExpanded(String?)

        // Showtime selection
        case showtimeTapped(Showtime)

        // Loading
        case loadCinemas
        case cinemasResponse([Cinema])
        case loadShowtimes(date: Date)
        case showtimesResponse([String: [Showtime]])   // [cinemaId: showtimes]
        case loadingFailed(Error)

        // GPS
        case locationUpdated(lat: Double, lon: Double)
        case locationDenied
    }

    // MARK: Dependencies

    @Dependency(\.showtimeRepository) var showtimeRepository

    // MARK: Reducer Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                return .merge(
                    .send(.loadCinemas),
                    .send(.loadShowtimes(date: state.selectedDate))
                )

            case .onDisappear:
                return .none

            case let .dateSelected(date):
                state.selectedDate = date
                state.showtimesByCinema = [:]   // Reset
                return .send(.loadShowtimes(date: date))

            case let .cinemaTapped(cinema):
                // Toggle accordion
                if state.expandedCinemaId == cinema.id {
                    state.expandedCinemaId = nil
                } else {
                    state.expandedCinemaId = cinema.id
                }
                return .none

            case let .cinemaExpanded(id):
                state.expandedCinemaId = id
                return .none

            case let .showtimeTapped(showtime):
                state.selectedShowtime = showtime
                return .none

            case .loadCinemas:
                state.isLoadingCinemas = true
                return .run { send in
                    do {
                        let cinemas = try await showtimeRepository.fetchCinemas()
                        await send(.cinemasResponse(cinemas))
                    } catch {
                        await send(.loadingFailed(error))
                    }
                }

            case let .cinemasResponse(cinemas):
                state.isLoadingCinemas = false
                state.cinemas = cinemas
                return .none

            case let .loadShowtimes(date):
                state.isLoadingShowtimes = true
                let movieId = state.movie.id
                return .run { [cinemas = state.cinemas] send in
                    do {
                        var grouped: [String: [Showtime]] = [:]
                        // Load showtimes cho mỗi rạp song song
                        try await withThrowingTaskGroup(of: (String, [Showtime]).self) { group in
                            for cinema in cinemas {
                                group.addTask {
                                    let shows = try await showtimeRepository.fetchShowtimesByDate(
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
                        await send(.showtimesResponse(grouped))
                    } catch {
                        await send(.loadingFailed(error))
                    }
                }

            case let .showtimesResponse(grouped):
                state.isLoadingShowtimes = false
                state.showtimesByCinema = grouped
                return .none

            case let .loadingFailed(error):
                state.isLoadingCinemas  = false
                state.isLoadingShowtimes = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .locationUpdated(lat, lon):
                state.userLatitude  = lat
                state.userLongitude = lon
                return .none

            case .locationDenied:
                state.userLatitude  = nil
                state.userLongitude = nil
                return .none
            }
        }
    }
}

// MARK: - Dependency Key

extension DependencyValues {
    var showtimeRepository: any ShowtimeRepositoryProtocol {
        get { self[ShowtimeRepositoryKey.self] }
        set { self[ShowtimeRepositoryKey.self] = newValue }
    }
}

private enum ShowtimeRepositoryKey: DependencyKey {
    static let liveValue: any ShowtimeRepositoryProtocol = MockShowtimeRepository()
    static let testValue: any ShowtimeRepositoryProtocol = MockShowtimeRepository()
}

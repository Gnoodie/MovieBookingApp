import SwiftUI

// MARK: - ShowtimePickerView

/// Màn hình chọn ngày → rạp → suất chiếu
/// Push từ MovieDetailView ("Mua Vé Ngay" button)
struct ShowtimePickerView: View {
    @StateObject private var viewModel: ShowtimeViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedShowtimeForSeatMap: Showtime? = nil

    init(movie: Movie) {
        _viewModel = StateObject(wrappedValue: ShowtimeViewModel(movie: movie, showtimeRepository: FirestoreCinemaRepository()))
    }

    var body: some View {
        ZStack {
            Color(hex: "#000000").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                ShowtimeHeader(
                    movieTitle: viewModel.movie.title,
                    onDismiss: { dismiss() }
                )

                // MARK: Date Picker Strip
                DatePickerStrip(
                    dates: viewModel.availableDates,
                    selectedDate: viewModel.selectedDate
                ) { date in
                    viewModel.selectedDate = date
                }
                .padding(.vertical, 12)

                // MARK: Cinema List
                if viewModel.isLoadingCinemas {
                    LoadingSection()
                } else if viewModel.sortedCinemas.isEmpty {
                    EmptyCinemasView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.sortedCinemas) { cinema in
                                CinemaAccordionView(
                                    cinema: cinema,
                                    showtimes: viewModel.showtimesByCinema[cinema.id] ?? [],
                                    isExpanded: viewModel.expandedCinemaId == cinema.id,
                                    isLoadingShowtimes: viewModel.isLoadingShowtimes,
                                    userLat: viewModel.userLatitude,
                                    userLon: viewModel.userLongitude,
                                    onCinemaTap: { viewModel.cinemaTapped(cinema) },
                                    onShowtimeTap: { showtime in
                                        viewModel.showtimeTapped(showtime)
                                        selectedShowtimeForSeatMap = showtime
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }

                Spacer(minLength: 0)
            }

            NavigationLink(
                destination: Group {
                    if let showtime = selectedShowtimeForSeatMap {
                        SeatMapView(showtime: showtime, movie: viewModel.movie)
                            .environmentObject(router)
                            .environmentObject(appViewModel)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { selectedShowtimeForSeatMap != nil },
                    set: { isActive in
                        if !isActive {
                            selectedShowtimeForSeatMap = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
    }
}

// MARK: - Header

private struct ShowtimeHeader: View {
    let movieTitle: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Chọn Suất Chiếu")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(movieTitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }
}

// MARK: - Loading

private struct LoadingSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(Color(hex: "#D4AF37"))
                .scaleEffect(1.3)
            Text("Đang tải rạp chiếu...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - Empty Cinemas

private struct EmptyCinemasView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "video.slash")
                .font(.system(size: 44))
                .foregroundColor(.gray)
            Text("Không có rạp chiếu")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Vui lòng thử ngày khác")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

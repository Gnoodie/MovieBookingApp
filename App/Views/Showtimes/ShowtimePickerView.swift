import SwiftUI
import ComposableArchitecture

// MARK: - ShowtimePickerView

/// Màn hình chọn ngày → rạp → suất chiếu
/// Push từ MovieDetailView ("Mua Vé Ngay" button)
struct ShowtimePickerView: View {
    @Bindable var store: StoreOf<ShowtimeFeature>
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#000000").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                ShowtimeHeader(
                    movieTitle: store.movie.title,
                    onDismiss: { dismiss() }
                )

                // MARK: Date Picker Strip
                DatePickerStrip(
                    dates: store.availableDates,
                    selectedDate: store.selectedDate
                ) { date in
                    store.send(.dateSelected(date))
                }
                .padding(.vertical, 12)

                // MARK: Cinema List
                if store.isLoadingCinemas {
                    LoadingSection()
                } else if store.sortedCinemas.isEmpty {
                    EmptyCinemasView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(store.sortedCinemas) { cinema in
                                CinemaAccordionView(
                                    cinema: cinema,
                                    showtimes: store.showtimesByCinema[cinema.id] ?? [],
                                    isExpanded: store.expandedCinemaId == cinema.id,
                                    isLoadingShowtimes: store.isLoadingShowtimes,
                                    userLat: store.userLatitude,
                                    userLon: store.userLongitude,
                                    onCinemaTap: { store.send(.cinemaTapped(cinema)) },
                                    onShowtimeTap: { showtime in
                                        store.send(.showtimeTapped(showtime))
                                        router.navigateTo(.seatMap(
                                            showtime: showtime,
                                            movie: store.movie
                                        ))
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
        }
        .navigationBarHidden(true)
        .onAppear { store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
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
            Image(systemName: "film.slash")
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

import SwiftUI
import ComposableArchitecture

// MARK: - HomeView

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack(path: Binding(
            get: { router.path },
            set: { router.path = $0 }
        )) {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#000000"),
                        Color(hex: "#0D0D1A"),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if store.isLoading && store.trendingMovies.isEmpty {
                    HomeLoadingView()
                } else if let errorMsg = store.errorMessage, store.trendingMovies.isEmpty {
                    HomeErrorView(message: errorMsg) {
                        store.send(.pullToRefresh)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // MARK: Hero Carousel
                            if !store.heroMovies.isEmpty {
                                HeroCarouselView(movies: store.heroMovies) { movie in
                                    router.navigateTo(.movieDetail(movie))
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.55)
                            }

                            // MARK: Search + Filter
                            VStack(spacing: 12) {
                                SearchBarView(text: Binding(
                                    get: { store.searchQuery },
                                    set: { store.send(.searchQueryChanged($0)) }
                                ))

                                FilterChipView(
                                    selectedFilter: store.selectedFilter
                                ) { filter in
                                    store.send(.filterChanged(filter))
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 16)

                            // MARK: Now Playing
                            if !store.nowPlayingMovies.isEmpty {
                                MovieSectionView(
                                    title: "Đang Chiếu",
                                    movies: store.displayMovies,
                                    onMovieTap: { router.navigateTo(.movieDetail($0)) }
                                )
                                .padding(.top, 24)
                            }

                            // MARK: Coming Soon
                            if !store.comingSoonMovies.isEmpty {
                                MovieSectionView(
                                    title: "Sắp Chiếu",
                                    movies: store.comingSoonMovies,
                                    onMovieTap: { router.navigateTo(.movieDetail($0)) }
                                )
                                .padding(.top, 8)
                            }

                            // Bottom padding for tab bar
                            Spacer().frame(height: 100)
                        }
                    }
                    .refreshable {
                        store.send(.pullToRefresh)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .movieDetail(let movie):
                    MovieDetailView(store: Store(
                        initialState: MovieDetailFeature.State(movie: movie)
                    ) {
                        MovieDetailFeature()
                    })
                    .environmentObject(router)

                case .showtimePicker(let movie):
                    ShowtimePickerView(store: Store(
                        initialState: ShowtimeFeature.State(movie: movie)
                    ) {
                        ShowtimeFeature()
                    })
                    .environmentObject(router)

                default:
                    PlaceholderView(title: "Sắp ra mắt trong Sprint tiếp theo")
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
    }
}

// MARK: - Search Bar

private struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Tìm kiếm phim...", text: $text)
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Movie Section (Horizontal Scroll)

private struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Button("Xem tất cả") {}
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#D4AF37"))
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(movies) { movie in
                        MovieCardView(movie: movie)
                            .onTapGesture { onMovieTap(movie) }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Loading View

private struct HomeLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(hex: "#D4AF37"))
                .scaleEffect(1.5)
            Text("Đang tải phim...")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

private struct HomeErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Không thể tải dữ liệu")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Thử lại") { onRetry() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color(hex: "#D4AF37"))
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text(title)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0D0D1A"))
    }
}

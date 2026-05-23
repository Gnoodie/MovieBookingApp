import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel(movieRepository: FirestoreMovieRepository())
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        NavigationView {
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

                if viewModel.isLoading && viewModel.trendingMovies.isEmpty {
                    HomeLoadingView()
                } else if let errorMsg = viewModel.errorMessage, viewModel.trendingMovies.isEmpty {
                    HomeErrorView(message: errorMsg) {
                        viewModel.pullToRefresh()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // MARK: Hero Carousel
                            if !viewModel.heroMovies.isEmpty {
                                HeroCarouselView(movies: viewModel.heroMovies)
                                    .frame(height: UIScreen.main.bounds.height * 0.55)
                            }

                            Spacer().frame(height: 16)

                            // MARK: Filters
                            FilterChipView(
                                selectedFilter: viewModel.selectedFilter,
                                onFilterSelected: { filter in
                                    viewModel.selectedFilter = filter
                                }
                            )
                            .padding(.horizontal, 16)

                            Spacer().frame(height: 8)

                            // MARK: Now Playing
                            if !viewModel.nowPlayingMovies.isEmpty {
                                MovieSectionView(
                                    title: "Đang Chiếu",
                                    movies: viewModel.displayMovies,
                                    onSeeAll: {
                                        appViewModel.selectedTab = .search
                                    }
                                )
                                .padding(.top, 24)
                            }

                            // MARK: Coming Soon
                            if !viewModel.comingSoonMovies.isEmpty {
                                MovieSectionView(
                                    title: "Sắp Chiếu",
                                    movies: viewModel.comingSoonMovies,
                                    onSeeAll: {
                                        appViewModel.selectedTab = .search
                                    }
                                )
                                .padding(.top, 8)
                            }

                            // Bottom padding for tab bar
                            Spacer().frame(height: 100)
                        }
                    }
                    .refreshable {
                        viewModel.pullToRefresh()
                    }
                }

            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.onAppear()
        }
    }
}


// MARK: - Movie Section (Horizontal Scroll)

private struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onSeeAll) {
                    Text("Xem tất cả")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#D4AF37"))
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            MovieCardView(movie: movie)
                        }
                        .buttonStyle(ScaleButtonStyle())
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

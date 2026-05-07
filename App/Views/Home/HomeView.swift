import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var router: AppRouter

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

                            // MARK: Search + Filter
                            VStack(spacing: 12) {
                                SearchBarView(text: $viewModel.searchQuery)

                                FilterChipView(
                                    selectedFilter: viewModel.selectedFilter
                                ) { filter in
                                    viewModel.selectedFilter = filter
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 16)

                            // MARK: Now Playing
                            if !viewModel.nowPlayingMovies.isEmpty {
                                MovieSectionView(
                                    title: "Đang Chiếu",
                                    movies: viewModel.displayMovies
                                )
                                .padding(.top, 24)
                            }

                            // MARK: Coming Soon
                            if !viewModel.comingSoonMovies.isEmpty {
                                MovieSectionView(
                                    title: "Sắp Chiếu",
                                    movies: viewModel.comingSoonMovies
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
    @EnvironmentObject var router: AppRouter
    let title: String
    let movies: [Movie]

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
                        NavigationLink(destination: MovieDetailView(movie: movie)
                            .environmentObject(router)
                        ) {
                            MovieCardView(movie: movie)
                        }
                        .buttonStyle(PlainButtonStyle())
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

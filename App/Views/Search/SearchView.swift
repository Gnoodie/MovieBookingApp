import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let movieRepository: MovieRepositoryProtocol
    private var searchTask: Task<Void, Never>? = nil

    init(movieRepository: MovieRepositoryProtocol = MockMovieRepository()) {
        self.movieRepository = movieRepository
    }

    func searchMovies() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard let self = self, !Task.isCancelled else { return }

            do {
                let movies = try await self.movieRepository.searchMovies(query: trimmed)
                guard !Task.isCancelled else { return }
                self.results = movies
                self.errorMessage = movies.isEmpty ? "Không tìm thấy phim phù hợp." : nil
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func clearSearch() {
        query = ""
        results = []
        errorMessage = nil
        isLoading = false
        searchTask?.cancel()
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#000000"), Color(hex: "#0D0D1A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    SearchBar(query: $viewModel.query, onCommit: viewModel.searchMovies, onClear: viewModel.clearSearch)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    if viewModel.query.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(.gray)
                            Text("Nhập tên phim để tìm kiếm")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                            Text("Tab tìm kiếm đã sẵn sàng. Gõ tên phim và chọn để xem chi tiết hoặc mua vé.")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 80)
                        Spacer()
                    } else if viewModel.isLoading {
                        VStack(spacing: 14) {
                            ProgressView()
                                .tint(Color(hex: "#D4AF37"))
                                .scaleEffect(1.3)
                            Text("Đang tìm kiếm...")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .padding(.top, 60)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 44))
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 60)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.results) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        SearchResultRow(movie: movie)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: viewModel.query) { _ in
            viewModel.searchMovies()
        }
    }
}

private struct SearchBar: View {
    @Binding var query: String
    let onCommit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Tìm kiếm phim...", text: $query, onCommit: onCommit)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button(action: onClear) {
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
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct SearchResultRow: View {
    let movie: Movie

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    Color(hex: "#1C1C1E")
                        .overlay(ProgressView().tint(Color(hex: "#D4AF37")))
                default:
                    Color(hex: "#1C1C1E")
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            }
            .frame(width: 76, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)

                Text(movie.originalTitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(movie.ageRating.displayLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(movie.ageRating.colorName).opacity(0.85))
                        .cornerRadius(10)

                    Text("\(movie.duration) phút")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
    }
}

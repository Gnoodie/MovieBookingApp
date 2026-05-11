import SwiftUI
import AVKit

// MARK: - MovieDetailView

struct MovieDetailView: View {
    @StateObject private var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showtimePickerActive = false

    init(movie: Movie) {
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(movie: movie))
    }

    var body: some View {
        ZStack {
            // Full black background
            Color(hex: "#000000").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: Hero Section (Backdrop + Trailer)
                    HeroSection(
                        movie: viewModel.movie,
                        isTrailerPlaying: viewModel.isTrailerPlaying,
                        onTrailerTap: { viewModel.trailerTapped() }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.40)

                    // MARK: Movie Info
                    VStack(alignment: .leading, spacing: 20) {
                        // Title + Rating row
                        TitleRatingRow(movie: viewModel.movie)

                        // Genre chips
                        GenreChipsRow(genres: viewModel.movie.genre)

                        // Synopsis
                        SynopsisSection(text: viewModel.movie.synopsis)

                        // Cast
                        if !viewModel.movie.cast.isEmpty {
                            CastRowView(cast: viewModel.movie.cast)
                        }

                        // Director
                        InfoRow(label: "Đạo diễn", value: viewModel.movie.director)

                        Spacer().frame(height: 100)  // Space for floating button
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }

            // MARK: Floating Buy Button
            VStack {
                Spacer()
                BuyTicketFloatingButton {
                    showtimePickerActive = true
                }
            }
            NavigationLink(
                destination: ShowtimePickerView(movie: viewModel.movie),
                isActive: $showtimePickerActive
            ) {
                EmptyView()
            }
            .hidden()

            // MARK: Back Button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)

                    Spacer()

                    // Favorite button
                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(viewModel.isFavorite ? .red : .white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 56)
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Hero Section

private struct HeroSection: View {
    let movie: Movie
    let isTrailerPlaying: Bool
    let onTrailerTap: () -> Void

    var body: some View {
        ZStack {
            if isTrailerPlaying, let trailerURL = movie.trailerURL {
                TrailerPlayerView(url: trailerURL)
            } else {
                // Backdrop image
                AsyncImage(url: movie.backdropURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ShimmerView()
                    default:
                        Color(hex: "#1C1C1E")
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()

                // Gradient to black at bottom
                LinearGradient(
                    colors: [Color.clear, Color.clear, Color(hex: "#000000")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Trailer play button
                if movie.trailerURL != nil {
                    Button(action: onTrailerTap) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 60, height: 60)
                            Image(systemName: "play.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .offset(x: 2)
                        }
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.4), radius: 12)
                    }
                }
            }
        }
    }
}

// MARK: - TrailerPlayerView

private struct TrailerPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let avPlayer = AVPlayer(url: url)
                avPlayer.isMuted = true
                avPlayer.play()
                self.player = avPlayer
            }
            .onDisappear {
                player?.pause()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Title & Rating Row

private struct TitleRatingRow: View {
    let movie: Movie

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)

                Text(movie.originalTitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }

            Spacer()

            RatingBadgeView(rating: movie.rating)
        }
    }
}

// MARK: - Genre Chips Row

private struct GenreChipsRow: View {
    let genres: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#00D4FF"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#00D4FF").opacity(0.12))
                        .overlay(
                            Capsule().strokeBorder(Color(hex: "#00D4FF").opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Synopsis Section

private struct SynopsisSection: View {
    let text: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nội dung")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.25), value: isExpanded)

            Button(isExpanded ? "Thu gọn" : "Xem thêm") {
                withAnimation { isExpanded.toggle() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#D4AF37"))
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Floating Buy Ticket Button

private struct BuyTicketFloatingButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Mua Vé Ngay")
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#D4AF37"), Color(hex: "#F0C850")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "#D4AF37").opacity(0.4), radius: 12, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: "#000000")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }
}

import SwiftUI

// MARK: - HeroCarouselView

/// Top 5 phim HOT với auto-scroll mỗi 5 giây
/// Poster tràn viền, gradient overlay phía dưới
struct HeroCarouselView: View {
    @EnvironmentObject var router: AppRouter
    let movies: [Movie]

    @State private var currentIndex: Int = 0
    @State private var isDragging: Bool = false

    // Auto-scroll timer
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: TabView Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(movies.enumerated()), id: \.offset) { index, movie in
                    NavigationLink(destination: MovieDetailView(movie: movie)
                        .environmentObject(router)
                    ) {
                        HeroSlideView(movie: movie)
                            .tag(index)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentIndex)

            // MARK: Bottom gradient + Info overlay
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Gradient fade
                LinearGradient(
                    colors: [.clear, Color(hex: "#000000")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)

                // Movie info
                if movies.indices.contains(currentIndex) {
                    HeroInfoOverlay(movie: movies[currentIndex])
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }

            // MARK: Page indicator dots
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(movies.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex
                                  ? Color(hex: "#D4AF37")
                                  : Color.white.opacity(0.3))
                            .frame(width: index == currentIndex ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .clipped()
        .onReceive(timer) { _ in
            guard !isDragging else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                currentIndex = (currentIndex + 1) % max(movies.count, 1)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { _ in isDragging = true }
                .onEnded { _ in
                    isDragging = false
                    // Resume auto-scroll sau 5s bằng cách không làm gì — timer sẽ tiếp tục
                }
        )
    }
}

// MARK: - Hero Slide (Single Item)

private struct HeroSlideView: View {
    let movie: Movie

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Backdrop image
                AsyncImage(url: movie.backdropURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .fill(Color(hex: "#1C1C1E"))
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "#1C1C1E"))
                            .overlay(
                                ProgressView()
                                    .tint(Color(hex: "#D4AF37"))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                // Subtle dark vignette
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.5),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Hero Info Overlay

private struct HeroInfoOverlay: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Age rating badge
            Text(movie.ageRating.displayLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(movie.ageRating.colorName).opacity(0.85))
                .cornerRadius(6)

            // Movie title
            Text(movie.title)
                .font(.system(size: 26, weight: .black, design: .default))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)

            // Genre + Duration row
            HStack(spacing: 8) {
                ForEach(movie.genre.prefix(2), id: \.self) { g in
                    Text(g)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                }
                Text("• \(movie.duration) phút")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            // CTA Row
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                    Text("Mua Vé")
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#D4AF37"))
                .cornerRadius(12)

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Chi tiết")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
}

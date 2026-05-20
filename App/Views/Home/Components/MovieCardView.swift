import SwiftUI

// MARK: - MovieCardView

/// Card hiển thị thông tin tóm tắt của một bộ phim
/// Dùng trong horizontal scroll section
struct MovieCardView: View {
    let movie: Movie

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Poster
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: movie.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        // Shimmer loading
                        ShimmerView()
                    case .failure:
                        Rectangle()
                            .fill(Color(hex: "#1C1C1E"))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 130, height: 195)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // IMDb-style rating badge
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#D4AF37"))
                    Text(String(format: "%.1f", movie.rating))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.75))
                .cornerRadius(8)
                .padding(8)
            }

            // MARK: Info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: 130, alignment: .leading)

                // Genre tag + age rating
                HStack(spacing: 4) {
                    if let genre = movie.genre.first {
                        Text(genre)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#00D4FF"))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(movie.ageRating.displayLabel)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.fromName(movie.ageRating.colorName).opacity(0.8))
                        .cornerRadius(4)
                }
                .frame(maxWidth: 130)
            }
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.01,
                            pressing: { pressing in isPressed = pressing },
                            perform: {})
    }
}

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#1C1C1E"))
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 400
                }
            }
    }
}

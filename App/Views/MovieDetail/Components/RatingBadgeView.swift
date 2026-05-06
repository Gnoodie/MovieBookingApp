import SwiftUI

// MARK: - RatingBadgeView

/// IMDb-style rating badge hiển thị điểm đánh giá phim
/// Màu theo mức: xanh (≥8.0), vàng (≥6.0), đỏ (<6.0)
struct RatingBadgeView: View {
    let rating: Double

    // MARK: Computed Properties

    private var ratingColor: Color {
        if rating >= 8.0 { return Color(hex: "#22C55E") }  // xanh lá
        if rating >= 6.0 { return Color(hex: "#D4AF37") }  // vàng
        return Color(hex: "#EF4444")                       // đỏ
    }

    private var formattedRating: String {
        String(format: "%.1f", rating)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                .frame(width: 54, height: 54)

            Circle()
                .trim(from: 0, to: rating / 10.0)
                .stroke(
                    ratingColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 54, height: 54)
                .animation(.easeOut(duration: 0.8), value: rating)

            // Score text
            VStack(spacing: 0) {
                Text(formattedRating)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(ratingColor)
                Text("IMDb")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Preview Helper

extension RatingBadgeView {
    static func preview(rating: Double) -> some View {
        RatingBadgeView(rating: rating)
            .padding()
            .background(Color(hex: "#000000"))
    }
}

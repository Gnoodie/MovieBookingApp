import SwiftUI

// MARK: - FilterChipView

/// Horizontal scrolling filter chips cho Home screen
/// Filters: "Tất cả", "2D", "3D", "IMAX", các thể loại
struct FilterChipView: View {
    let selectedFilter: MovieFilter
    let onFilterSelected: (MovieFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MovieFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        onFilterSelected(filter)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Single Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "#D4AF37"), Color(hex: "#B8960A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.08)
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

import SwiftUI

// MARK: - CinemaAccordionView

/// Accordion card cho từng rạp chiếu phim
/// Mở/đóng để hiện danh sách suất chiếu
struct CinemaAccordionView: View {
    let cinema: Cinema
    let showtimes: [Showtime]
    let isExpanded: Bool
    let isLoadingShowtimes: Bool
    let userLat: Double?
    let userLon: Double?
    let onCinemaTap: () -> Void
    let onShowtimeTap: (Showtime) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Cinema Header (tappable)
            Button(action: onCinemaTap) {
                HStack(spacing: 14) {
                    // Brand logo placeholder
                    BrandBadge(brand: cinema.brand)

                    // Cinema info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cinema.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Text(cinema.district + ", " + cinema.city)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            if let distance = distanceString {
                                Text("•")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 10))
                                Text(distance)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#00D4FF"))
                            }
                        }

                        // Amenity chips (max 3)
                        HStack(spacing: 6) {
                            ForEach(cinema.amenities.prefix(3), id: \.self) { amenity in
                                Text(amenity.rawValue)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(4)
                            }
                        }
                    }

                    Spacer()

                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // MARK: Showtimes (Expanded)
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.08))

                if isLoadingShowtimes {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "#D4AF37"))
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if showtimes.isEmpty {
                    Text("Không có suất chiếu trong ngày này")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                } else {
                    // Group showtimes by format
                    let grouped = Dictionary(grouping: showtimes) { $0.format.badge }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(grouped.keys.sorted(), id: \.self) { formatKey in
                            if let shows = grouped[formatKey] {
                                ShowtimeFormatGroup(
                                    formatBadge: formatKey,
                                    showtimes: shows,
                                    onShowtimeTap: onShowtimeTap
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }

    // MARK: - Distance String

    private var distanceString: String? {
        guard let lat = userLat, let lon = userLon else { return nil }
        let R = 6371.0
        let lat1 = lat * .pi / 180
        let lat2 = cinema.latitude * .pi / 180
        let dLat = (cinema.latitude - lat) * .pi / 180
        let dLon = (cinema.longitude - lon) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let km = R * 2 * atan2(sqrt(a), sqrt(1 - a))
        return km < 1 ? "\(Int(km * 1000))m" : String(format: "%.1f km", km)
    }
}

// MARK: - Brand Badge

private struct BrandBadge: View {
    let brand: Cinema.Brand

    private var brandColor: Color {
        switch brand {
        case .cgv:    return Color(hex: "#E50914")
        case .lotte:  return Color(hex: "#DC0032")
        case .bhd:    return Color(hex: "#FF6600")
        case .galaxy: return Color(hex: "#6B46C1")
        case .dcine:  return Color(hex: "#0EA5E9")
        case .other:  return Color.gray
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(brandColor.opacity(0.15))
                .frame(width: 44, height: 44)
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(brandColor.opacity(0.4), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            Text(String(brand.rawValue.prefix(3)))
                .font(.system(size: 11, weight: .black))
                .foregroundColor(brandColor)
        }
    }
}

// MARK: - Format Group Row

private struct ShowtimeFormatGroup: View {
    let formatBadge: String
    let showtimes: [Showtime]
    let onShowtimeTap: (Showtime) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(formatBadge)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)

            // Showtime badges in horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(showtimes) { showtime in
                        ShowtimeBadgeView(showtime: showtime)
                            .onTapGesture { onShowtimeTap(showtime) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}


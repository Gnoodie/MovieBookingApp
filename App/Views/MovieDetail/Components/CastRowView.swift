import SwiftUI

// MARK: - CastRowView

/// Horizontal scroll của danh sách diễn viên với avatar placeholder
struct CastRowView: View {
    let cast: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diễn viên")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(cast, id: \.self) { actorName in
                        CastAvatarView(name: actorName)
                    }
                }
            }
        }
    }
}

// MARK: - Cast Avatar

private struct CastAvatarView: View {
    let name: String

    /// Initials từ tên diễn viên (tối đa 2 ký tự)
    private var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String((parts.first?.prefix(1) ?? "") + (parts.last?.prefix(1) ?? ""))
        }
        return String(name.prefix(2))
    }

    /// Màu avatar dựa trên hash tên (consistent màu cho mỗi diễn viên)
    private var avatarColor: Color {
        let colors: [Color] = [
            Color(hex: "#D4AF37"),
            Color(hex: "#00D4FF"),
            Color(hex: "#FF6B6B"),
            Color(hex: "#7C3AED"),
            Color(hex: "#059669"),
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Circle()
                    .strokeBorder(avatarColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 60, height: 60)

                Text(initials.uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(avatarColor)
            }

            // Name
            Text(name.components(separatedBy: " ").first ?? name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .frame(maxWidth: 64)
        }
    }
}

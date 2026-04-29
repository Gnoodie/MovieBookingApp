import Foundation

// MARK: - Movie

/// Entity đại diện cho một bộ phim trong hệ thống
struct Movie: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let title: String               // Tên tiếng Việt hiển thị
    let originalTitle: String       // Tên gốc (tiếng Anh, Hàn...)
    let posterURL: URL?             // Ảnh poster dọc
    let backdropURL: URL?           // Ảnh nền ngang (hero banner)
    let synopsis: String            // Tóm tắt nội dung
    let duration: Int               // Thời lượng (phút)
    let rating: Double              // Điểm đánh giá 0.0 – 10.0
    let genre: [String]             // Thể loại: ["Hành động", "Khoa học viễn tưởng"]
    let releaseDate: Date
    let ageRating: AgeRating
    let trailerURL: URL?
    let cast: [String]              // Diễn viên chính
    let director: String

    // MARK: - Nested Types

    enum AgeRating: String, Codable, CaseIterable {
        case general = "P"      // Mọi lứa tuổi
        case teens13 = "T13"    // Từ 13 tuổi
        case teens16 = "T16"    // Từ 16 tuổi
        case adults18 = "T18"   // Từ 18 tuổi

        /// Nhãn hiển thị trên UI
        var displayLabel: String { rawValue }

        /// Màu nhãn (dùng trong DesignSystem)
        var colorName: String {
            switch self {
            case .general:  return "statusSuccess"
            case .teens13:  return "accentTeal"
            case .teens16:  return "statusWarning"
            case .adults18: return "statusError"
            }
        }
    }
}

// MARK: - Mock Data

extension Movie {
    static let mocks: [Movie] = [
        Movie(
            id: "movie-001",
            title: "Người Nhện: Vũ Trụ Mới",
            originalTitle: "Spider-Man: New Universe",
            posterURL: URL(string: "https://picsum.photos/seed/movie1/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie1bg/1200/600"),
            synopsis: "Peter Parker phải đối mặt với mối đe dọa từ đa vũ trụ khi các phản diện từ các chiều không gian khác xâm nhập vào thế giới của anh.",
            duration: 148,
            rating: 8.4,
            genre: ["Hành động", "Khoa học viễn tưởng"],
            releaseDate: Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=example"),
            cast: ["Tom Holland", "Zendaya", "Benedict Cumberbatch"],
            director: "Jon Watts"
        ),
        Movie(
            id: "movie-002",
            title: "Kẻ Trộm Mặt Trăng 4",
            originalTitle: "Despicable Me 4",
            posterURL: URL(string: "https://picsum.photos/seed/movie2/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie2bg/1200/600"),
            synopsis: "Gru và gia đình tiếp tục hành trình mới với những tên Minion đáng yêu trong cuộc phiêu lưu đầy bất ngờ.",
            duration: 95,
            rating: 7.1,
            genre: ["Hoạt hình", "Hài hước", "Gia đình"],
            releaseDate: Date(),
            ageRating: .general,
            trailerURL: nil,
            cast: ["Steve Carell", "Kristen Wiig"],
            director: "Chris Renaud"
        ),
        Movie(
            id: "movie-003",
            title: "Dune: Phần Hai",
            originalTitle: "Dune: Part Two",
            posterURL: URL(string: "https://picsum.photos/seed/movie3/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie3bg/1200/600"),
            synopsis: "Paul Atreides tiếp tục hành trình của mình trên hành tinh Arrakis, liên minh với người Fremen để trả thù những kẻ đã hủy hoại gia đình anh.",
            duration: 166,
            rating: 8.8,
            genre: ["Khoa học viễn tưởng", "Sử thi"],
            releaseDate: Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=example2"),
            cast: ["Timothée Chalamet", "Zendaya", "Rebecca Ferguson"],
            director: "Denis Villeneuve"
        ),
    ]
}

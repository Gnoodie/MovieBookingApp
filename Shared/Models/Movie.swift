import Foundation

// MARK: - Movie

/// Entity đại diện cho một bộ phim trong hệ thống
public struct Movie: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public let title: String               // Tên tiếng Việt hiển thị
    public let originalTitle: String       // Tên gốc (tiếng Anh, Hàn...)
    public let posterURL: URL?             // Ảnh poster dọc
    public let backdropURL: URL?           // Ảnh nền ngang (hero banner)
    public let synopsis: String            // Tóm tắt nội dung
    public let duration: Int               // Thời lượng (phút)
    public let rating: Double              // Điểm đánh giá 0.0 – 10.0
    public let genre: [String]             // Thể loại: ["Hành động", "Khoa học viễn tưởng"]
    public let releaseDate: Date
    public let ageRating: AgeRating
    public let trailerURL: URL?
    public let cast: [String]              // Diễn viên chính
    public let director: String
    public let isNowPlaying: Bool          // true = đang chiếu, false = sắp chiếu

    // MARK: - Nested Types

    public enum AgeRating: String, Codable, CaseIterable {
        case general = "P"      // Mọi lứa tuổi
        case teens13 = "T13"    // Từ 13 tuổi
        case teens16 = "T16"    // Từ 16 tuổi
        case adults18 = "T18"   // Từ 18 tuổi

        /// Nhãn hiển thị trên UI
        public var displayLabel: String { rawValue }

        /// Màu nhãn (dùng trong DesignSystem)
        public var colorName: String {
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
            director: "Jon Watts",
            isNowPlaying: true
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
            director: "Chris Renaud",
            isNowPlaying: true
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
            director: "Denis Villeneuve",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-004",
            title: "Ma Tốc Độ",
            originalTitle: "The Fast Haunting",
            posterURL: URL(string: "https://picsum.photos/seed/movie4/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie4bg/1200/600"),
            synopsis: "Một nhóm tài xế đua phát hiện đường đua bí ẩn bị ám bởi những linh hồn chưa siêu thoát. Ranh giới giữa thế giới thực và địa ngục mờ dần.",
            duration: 112,
            rating: 7.5,
            genre: ["Kinh dị", "Hành động"],
            releaseDate: Date(),
            ageRating: .teens16,
            trailerURL: URL(string: "https://youtube.com/watch?v=example3"),
            cast: ["Ngô Thanh Vân", "Trấn Thành", "Kaity Nguyễn"],
            director: "Võ Thanh Hòa",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-005",
            title: "Bộ Tứ Siêu Đẳng: Bắt Đầu",
            originalTitle: "The Fantastic Four: First Steps",
            posterURL: URL(string: "https://picsum.photos/seed/movie5/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie5bg/1200/600"),
            synopsis: "Reed Richards và Susan Storm dẫn đầu đội siêu anh hùng đầu tiên của Marvel trong thế giới retro-futuristic đầy phong cách.",
            duration: 134,
            rating: 8.2,
            genre: ["Hành động", "Phiêu lưu", "Gia đình"],
            releaseDate: Date(),
            ageRating: .general,
            trailerURL: URL(string: "https://youtube.com/watch?v=example4"),
            cast: ["Pedro Pascal", "Vanessa Kirby", "Joseph Quinn"],
            director: "Matt Shakman",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-006",
            title: "Những Ngôi Sao Lạc Lối",
            originalTitle: "Lost Among Stars",
            posterURL: URL(string: "https://picsum.photos/seed/movie6/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie6bg/1200/600"),
            synopsis: "Câu chuyện tình yêu vượt thời gian giữa một nhạc sĩ và một nhà thiên văn học. Hai người vô tình trao đổi nhật ký qua những thiên thạch.",
            duration: 118,
            rating: 8.9,
            genre: ["Tâm lý", "Lãng mạn"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            ageRating: .general,
            trailerURL: URL(string: "https://youtube.com/watch?v=example5"),
            cast: ["Jenna Ortega", "Jacob Elordi"],
            director: "Lulu Wang",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-007",
            title: "Đất Không Bình Yên",
            originalTitle: "Quiet Earth",
            posterURL: URL(string: "https://picsum.photos/seed/movie7/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie7bg/1200/600"),
            synopsis: "Một người nông dân bình thường trở thành anh hùng khi ngôi làng nhỏ phải đối mặt với thế lực bóng tối từ dưới lòng đất.",
            duration: 105,
            rating: 7.8,
            genre: ["Kinh dị", "Hồi hộp"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            ageRating: .teens16,
            trailerURL: nil,
            cast: ["Hoàng Yến Chibi", "Bảo Thanh", "Kiều Minh Tuấn"],
            director: "Lê Văn Kiệt",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-008",
            title: "Biệt Đội Robot Siêu Cấp",
            originalTitle: "Robots United",
            posterURL: URL(string: "https://picsum.photos/seed/movie8/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie8bg/1200/600"),
            synopsis: "Năm 2087, một nhóm robot có ý thức phải cứu nhân loại khỏi đại dịch năng lượng. Hành trình từ Hà Nội đến vũ trụ đầy nguy hiểm.",
            duration: 142,
            rating: 7.9,
            genre: ["Hoạt hình", "Khoa học viễn tưởng"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            ageRating: .general,
            trailerURL: URL(string: "https://youtube.com/watch?v=example6"),
            cast: ["Ryan Reynolds", "Emma Stone"],
            director: "Brad Bird",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-009",
            title: "Lửa Thiêng Sông Hồng",
            originalTitle: "Red River Fire",
            posterURL: URL(string: "https://picsum.photos/seed/movie9/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie9bg/1200/600"),
            synopsis: "Dựa trên câu chuyện có thật về đội cứu hỏa dũng cảm trong trận hỏa hoạn lịch sử tại Hà Nội năm 2004. Một bộ phim đầy cảm xúc về lòng dũng cảm và hi sinh.",
            duration: 128,
            rating: 9.1,
            genre: ["Tâm lý", "Chính kịch", "Lịch sử"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=example7"),
            cast: ["Thành Lộc", "Mỹ Tâm", "Xuân Hinh"],
            director: "Nguyễn Quang Dũng",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-010",
            title: "Avengers: Kỷ Nguyên Mới",
            originalTitle: "Avengers: New Age",
            posterURL: URL(string: "https://picsum.photos/seed/movie10/400/600"),
            backdropURL: URL(string: "https://picsum.photos/seed/movie10bg/1200/600"),
            synopsis: "Một thế hệ Avengers hoàn toàn mới tập hợp để đối mặt với mối đe dọa từ một thực thể vũ trụ có thể xóa bỏ toàn bộ thực tại.",
            duration: 180,
            rating: 8.6,
            genre: ["Hành động", "Phiêu lưu", "Khoa học viễn tưởng"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=example8"),
            cast: ["Florence Pugh", "Tenoch Huerta", "Hailee Steinfeld", "Anthony Mackie"],
            director: "Sharmeen Obaid-Chinoy",
            isNowPlaying: false
        ),
    ]

    // MARK: - Computed sub-lists

    static var nowPlaying: [Movie] {
        mocks.filter { $0.isNowPlaying }
    }

    static var comingSoon: [Movie] {
        mocks.filter { !$0.isNowPlaying }
    }
}

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
            posterURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/poster/Nguoinhenvutrumoi.png?updatedAt=1778232802540"),
            backdropURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/backdrop/nguoinhenvutrumoi_backdrop.jpg?updatedAt=1778232772931"),
            synopsis: "Peter Parker phải đối mặt với mối đe dọa từ đa vũ trụ khi các phản diện từ các chiều không gian khác xâm nhập vào thế giới của anh.",
            duration: 148,
            rating: 8.4,
            genre: ["Hành động", "Khoa học viễn tưởng"],
            releaseDate: Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=JfVOs4VSpmA"),
            cast: ["Tom Holland", "Zendaya", "Benedict Cumberbatch"],
            director: "Jon Watts",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-002",
            title: "Kẻ Trộm Mặt Trăng 4",
            originalTitle: "Despicable Me 4",
            posterURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/poster/ketrommattrang4.jpg?updatedAt=1778232802431"),
            backdropURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/backdrop/ketrommattrang4_backdrop.jpg?updatedAt=1778232773155"),
            synopsis: "Gru và gia đình tiếp tục hành trình mới với những tên Minion đáng yêu trong cuộc phiêu lưu đầy bất ngờ.",
            duration: 95,
            rating: 7.1,
            genre: ["Hoạt hình", "Hài hước", "Gia đình"],
            releaseDate: Date(),
            ageRating: .general,
            trailerURL: URL(string: "https://youtube.com/watch?v=ex3bLBaRRVU"),
            cast: ["Steve Carell", "Kristen Wiig"],
            director: "Chris Renaud",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-003",
            title: "Dune: Phần Hai",
            originalTitle: "Dune: Part Two",
            posterURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/poster/Dune.jpg?updatedAt=1778232802341"),
            backdropURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/backdrop/dune_backdrop.jpg?updatedAt=1778232772628"),
            synopsis: "Paul Atreides tiếp tục hành trình của mình trên hành tinh Arrakis, liên minh với người Fremen để trả thù những kẻ đã hủy hoại gia đình anh.",
            duration: 166,
            rating: 8.8,
            genre: ["Khoa học viễn tưởng", "Sử thi"],
            releaseDate: Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=Way9Dexny3w"),
            cast: ["Timothée Chalamet", "Zendaya", "Rebecca Ferguson"],
            director: "Denis Villeneuve",
            isNowPlaying: true
        ),
        Movie(
            id: "movie-004",
            title: "Ma Tốc Độ",
            originalTitle: "The Fast Haunting",
            posterURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/poster/matocdo.jpg?updatedAt=1778232802404"),
            backdropURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/backdrop/matocdo_backdrop.jpg?updatedAt=1778232772922"),
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
            posterURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/poster/botusieudang.jpg?updatedAt=1778232801775"),
            backdropURL: URL(string: "https://ik.imagekit.io/wlyzz5nua/movies/backdrop/botusieudang_backdrop.jpeg?updatedAt=1778232772471"),
            synopsis: "Reed Richards và Susan Storm dẫn đầu đội siêu anh hùng đầu tiên của Marvel trong thế giới retro-futuristic đầy phong cách.",
            duration: 134,
            rating: 8.2,
            genre: ["Hành động", "Phiêu lưu", "Gia đình"],
            releaseDate: Date(),
            ageRating: .general,
            trailerURL: URL(string: "https://youtube.com/watch?v=eO4LU96uLis"),
            cast: ["Pedro Pascal", "Vanessa Kirby", "Joseph Quinn"],
            director: "Matt Shakman",
            isNowPlaying: true
        ),

        // MARK: - Sắp chiếu (5 phim quốc tế nổi tiếng)

        Movie(
            id: "movie-006",
            title: "Oppenheimer",
            originalTitle: "Oppenheimer",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg"),
            synopsis: "Câu chuyện về J. Robert Oppenheimer — nhà vật lý thiên tài đã lãnh đạo Dự án Manhattan để chế tạo quả bom nguyên tử đầu tiên trong lịch sử nhân loại.",
            duration: 180,
            rating: 8.9,
            genre: ["Chính kịch", "Lịch sử", "Tiểu sử"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            ageRating: .teens16,
            trailerURL: URL(string: "https://youtube.com/watch?v=uYPbbksJxIg"),
            cast: ["Cillian Murphy", "Emily Blunt", "Matt Damon", "Robert Downey Jr."],
            director: "Christopher Nolan",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-007",
            title: "Top Gun: Maverick",
            originalTitle: "Top Gun: Maverick",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/odJ4hx6g6vBt4lBWKFD1tI8WS1c.jpg"),
            synopsis: "Sau hơn 30 năm phục vụ, Pete 'Maverick' Mitchell vẫn đang đẩy giới hạn tốc độ như một phi công thử nghiệm. Anh được triệu hồi để huấn luyện thế hệ phi công mới cho một nhiệm vụ gần như không thể.",
            duration: 131,
            rating: 8.3,
            genre: ["Hành động", "Phiêu lưu"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=qSqVVswa420"),
            cast: ["Tom Cruise", "Miles Teller", "Jennifer Connelly", "Jon Hamm"],
            director: "Joseph Kosinski",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-008",
            title: "Interstellar",
            originalTitle: "Interstellar",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg"),
            synopsis: "Khi Trái Đất đứng trước nguy cơ diệt vong, một nhóm phi hành gia dũng cảm đã vượt qua lỗ sâu không gian để tìm kiếm hành tinh mới cho nhân loại — và khám phá bí ẩn về thời gian, không gian và tình yêu.",
            duration: 169,
            rating: 8.7,
            genre: ["Khoa học viễn tưởng", "Phiêu lưu", "Chính kịch"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=zSWdZVtXT7E"),
            cast: ["Matthew McConaughey", "Anne Hathaway", "Jessica Chastain"],
            director: "Christopher Nolan",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-009",
            title: "Avatar: Dòng Chảy Của Nước",
            originalTitle: "Avatar: The Way of Water",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/s16H6tpK2utvwDtzZ8Qy4impTDa.jpg"),
            synopsis: "Jake Sully và Neytiri đang cố gắng giữ cho gia đình an toàn. Khi một mối đe dọa quen thuộc trở lại, họ phải rời bỏ ngôi nhà và khám phá những vùng đại dương hẻo lánh của Pandora.",
            duration: 192,
            rating: 7.6,
            genre: ["Hành động", "Phiêu lưu", "Khoa học viễn tưởng"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            ageRating: .teens13,
            trailerURL: URL(string: "https://youtube.com/watch?v=d9MyW72ELq0"),
            cast: ["Sam Worthington", "Zoe Saldana", "Sigourney Weaver", "Kate Winslet"],
            director: "James Cameron",
            isNowPlaying: false
        ),
        Movie(
            id: "movie-010",
            title: "The Dark Knight",
            originalTitle: "The Dark Knight",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/1hYMHIKkJiwIjEiVBHVmIUJcYnE.jpg"),
            synopsis: "Batman đặt ra mục tiêu tiêu diệt tội phạm có tổ chức ở Gotham cùng với Jim Gordon và Harvey Dent. Nhưng kẻ thù mang tên Joker xuất hiện, đẩy cả thành phố vào hỗn loạn tột cùng.",
            duration: 152,
            rating: 9.0,
            genre: ["Hành động", "Tội phạm", "Chính kịch"],
            releaseDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
            ageRating: .teens16,
            trailerURL: URL(string: "https://youtube.com/watch?v=EXeTwQWrcwY"),
            cast: ["Christian Bale", "Heath Ledger", "Aaron Eckhart", "Michael Caine"],
            director: "Christopher Nolan",
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

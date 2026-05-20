import AppIntents
import SwiftUI

@available(iOS 18.0, *)
struct BookMovieIntent: AppIntent {
    static let title: LocalizedStringResource = "Đặt vé phim"
    static let description = IntentDescription("Đặt vé một bộ phim bất kỳ qua Siri")
    
    // Nếu thiếu thông tin, Siri sẽ tự động đọc câu thoại trong requestValueDialog để hỏi lại người dùng
    @Parameter(title: "Phim", requestValueDialog: "Bạn muốn xem phim gì?")
    var movie: MovieEntity
    
    @Parameter(title: "Rạp chiếu", requestValueDialog: "Bạn muốn xem ở rạp nào?")
    var cinema: CinemaEntity
    
    @Parameter(title: "Suất chiếu", requestValueDialog: "Bạn chọn suất chiếu lúc mấy giờ?")
    var showtime: ShowtimeEntity
    
    // Đặt false để Siri phản hồi trực tiếp mà không cần bật app lên (Zero-UI)
    static var openAppWhenRun: Bool = false 
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Siri sẽ đọc to câu thoại này
        let dialog = IntentDialog("Tuyệt vời. Tôi đã giữ chỗ cho phim \(movie.title) tại \(cinema.name), suất \(showtime.timeString). Bạn có thể thanh toán ngay trên màn hình.")
        
        // Siri sẽ hiển thị giao diện BookingSnippetView
        return .result(
            dialog: dialog,
            view: BookingSnippetView(movie: movie, cinema: cinema, showtime: showtime)
        )
    }
}

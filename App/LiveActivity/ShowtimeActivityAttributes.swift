#if canImport(ActivityKit)
import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct ShowtimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var minutesRemaining: Int
        var isStartingSoon: Bool  // < 15 phút
    }
    
    let movieTitle: String
    let cinemaName: String
    let hallName: String
    let seatLabels: String
    let showtimeString: String  // Ví dụ: "20:30"
}
#endif

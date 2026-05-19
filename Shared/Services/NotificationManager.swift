import Foundation
import UserNotifications
import os.log

/// Manager xử lý hệ thống Push Notification cục bộ (Local Notifications) cho iOS 15+
final class NotificationManager {
    static let shared = NotificationManager()
    private static let logger = Logger(subsystem: "com.cinematicket", category: "Notifications")
    
    private init() {}
    
    /// Xin quyền gửi thông báo từ người dùng
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                Self.logger.info("✅ Notification permission granted.")
            } else if let error = error {
                Self.logger.error("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Lên lịch nhắc nhở người dùng trước khi phim chiếu
    func scheduleMovieReminder(for ticket: Ticket) {
        // Nhắc trước 1 tiếng
        let oneHourBefore = ticket.showtime.addingTimeInterval(-3600)
        if oneHourBefore > Date() {
            scheduleNotification(
                id: "\(ticket.bookingId)_1h",
                title: "Sắp đến giờ chiếu!",
                body: "Phim \(ticket.movieTitle) sẽ bắt đầu lúc \(formattedTime(ticket.showtime)) tại phòng chiếu \(ticket.hallName). Nhấn để xem vé của bạn.",
                date: oneHourBefore
            )
        }
        
        // Nhắc trước 15 phút
        let fifteenMinsBefore = ticket.showtime.addingTimeInterval(-900)
        if fifteenMinsBefore > Date() {
            scheduleNotification(
                id: "\(ticket.bookingId)_15m",
                title: "Chuẩn bị vào rạp!",
                body: "Phim \(ticket.movieTitle) sắp bắt đầu. Vui lòng di chuyển đến rạp \(ticket.cinemaName).",
                date: fifteenMinsBefore
            )
        }
        
#if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            // Auto-end Live Activity sau showtime + 15 phút (chỉ khi app còn sống)
            let endTime = ticket.showtime.addingTimeInterval(15 * 60)
            let delay = endTime.timeIntervalSinceNow
            if delay > 0 {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await LiveActivityManager.shared.endActivity()
                }
            }
        }
#endif
    }
    
    /// Lên lịch nhắc nhở giữ ghế nếu đưa app xuống background
    func scheduleHoldReminder(expireDate: Date) {
        let reminderTime = expireDate.addingTimeInterval(-120) // Nhắc trước 2 phút khi hết hạn giữ ghế
        if reminderTime > Date() {
            scheduleNotification(
                id: "hold_seat_reminder",
                title: "Sắp hết thời gian giữ ghế!",
                body: "Ghế của bạn sẽ bị huỷ giữ trong 2 phút nữa. Vui lòng hoàn tất thanh toán.",
                date: reminderTime
            )
        }
    }
    
    /// Tuỷ bỏ nhắc nhở giữ ghế (khi đã thanh toán thành công hoặc huỷ vé)
    func cancelHoldReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["hold_seat_reminder"])
    }
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Self.logger.error("❌ Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

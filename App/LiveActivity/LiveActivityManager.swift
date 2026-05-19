#if canImport(ActivityKit)
import ActivityKit
import Foundation
import os.log

@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<ShowtimeActivityAttributes>?
    
    private let logger = Logger(subsystem: "com.cinematicket", category: "LiveActivity")
    
    private init() {}
    
    func startActivity(for ticket: Ticket) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are disabled by user")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let showtimeString = formatter.string(from: ticket.showtime)
        
        let attributes = ShowtimeActivityAttributes(
            movieTitle: ticket.movieTitle,
            cinemaName: ticket.cinemaName,
            hallName: ticket.hallName,
            seatLabels: ticket.seats.map { $0.displayName }.joined(separator: ", "),
            showtimeString: showtimeString
        )
        
        let minutesRemaining = max(0, Int(ticket.showtime.timeIntervalSinceNow / 60))
        let initialContentState = ShowtimeActivityAttributes.ContentState(
            minutesRemaining: minutesRemaining,
            isStartingSoon: minutesRemaining <= 15
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil
            )
            self.currentActivity = activity
            logger.info("Live Activity started successfully with id: \(activity.id)")
        } catch {
            logger.error("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(minutesRemaining: Int) async {
        guard let activity = currentActivity else { return }
        
        let updatedContentState = ShowtimeActivityAttributes.ContentState(
            minutesRemaining: minutesRemaining,
            isStartingSoon: minutesRemaining <= 15
        )
        
        await activity.update(using: updatedContentState)
    }
    
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalContentState = ShowtimeActivityAttributes.ContentState(
            minutesRemaining: 0,
            isStartingSoon: true
        )
        
        await activity.end(using: finalContentState, dismissalPolicy: .default)
        self.currentActivity = nil
        logger.info("Live Activity ended successfully")
    }
}
#endif

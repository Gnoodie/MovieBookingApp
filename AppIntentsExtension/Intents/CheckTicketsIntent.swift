import AppIntents
import SwiftUI

@available(iOS 18.0, *)
struct CheckTicketsIntent: AppIntent {
    static let title: LocalizedStringResource = "Xem vé của tôi"
    static let description = IntentDescription("Mở danh sách vé đã mua")
    
    // Bring app to foreground
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        if let url = URL(string: "cinematicket://tickets") {
            _ = await UIApplication.shared.open(url)
        }
        return .result()
    }
}

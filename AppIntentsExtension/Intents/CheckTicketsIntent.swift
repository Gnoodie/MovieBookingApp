import AppIntents
import SwiftUI

@available(iOS 18.0, *)
struct CheckTicketsIntent: AppIntent {
    static let title: LocalizedStringResource = "Xem vé của tôi"
    static let description = IntentDescription("Mở danh sách vé đã mua")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "cinematicket://tickets")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

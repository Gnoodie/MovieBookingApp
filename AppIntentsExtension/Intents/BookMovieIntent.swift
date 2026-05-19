import AppIntents
import SwiftUI

@available(iOS 17.0, *)
struct BookMovieIntent: AppIntent {
    static let title: LocalizedStringResource = "Đặt vé phim"
    static let description = IntentDescription("Mở màn hình đặt vé cho một bộ phim")
    
    @Parameter(title: "Tên phim")
    var movieName: String?
    
    // Add openAppWhenRun to bring the app to the foreground
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let encodedName = movieName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "cinematicket://search?q=\(encodedName)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        
        return .result()
    }
}

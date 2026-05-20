import Foundation
import FirebaseCore

@available(iOS 18.0, *)
struct FirebaseIntentSetup {
    static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured from App Intents")
        }
    }
}

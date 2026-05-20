import Foundation
import FirebaseCore
import FirebaseFirestore

@available(iOS 18.0, *)
struct FirebaseIntentSetup {
    static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            
            // Tắt persistence cho App Intents để ép ghi trực tiếp qua mạng
            // Tránh việc extension bị terminate trước khi kịp sync dữ liệu
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = false
            Firestore.firestore().settings = settings
            
            print("🔥 Firebase configured from App Intents with persistence disabled")
        }
    }
}

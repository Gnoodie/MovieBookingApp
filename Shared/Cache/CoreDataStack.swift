import CoreData
import Foundation

/// Lớp quản lý bộ đệm nội bộ (Local Cache) sử dụng CoreData.
/// Sẽ được dùng để lưu các phim hoặc vé để xem khi không có mạng.
public class CoreDataStack {
    public static let shared = CoreDataStack()
    
    public let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "MovieBookingApp")
        
        // Hỗ trợ lưu trữ trong bộ nhớ tạm (in-memory) nếu đang chạy Unit Test
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Lỗi khởi tạo CoreData: \(error.localizedDescription)")
            }
        }
        
        // Cấu hình tự động gộp các thay đổi từ Background Thread
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Lưu các thay đổi nếu có
    public func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Lỗi lưu CoreData: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    // MARK: - Singleton (單例模式)
    
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack (Core Data 堆疊)
    
    /// 取得目前的 Managed Object Context
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    // MARK: - Saving (儲存)
    
    /// 儲存當前的 Context 變更
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Operations (增山查改)
    
    /// 建立新的行程項目
    /// - Parameters:
    ///   - type: 項目類型 (例如: transport, hotel)
    ///   - timestamp: 時間戳
    ///   - title: 標題
    ///   - locationName: 地點名稱
    ///   - price: 價格
    ///   - locationURL: 地點連結
    ///   - memo: 備註
    ///   - photoData: 照片資料
    ///   - transportDuration: 交通時間
    ///   - iconName: 圖示名稱
    /// - Returns: 建立的 ItineraryItem
    @discardableResult
    func createItem(
        type: String,
        timestamp: Date,
        title: String,
        locationName: String,
        price: Double,
        locationURL: String? = nil,
        memo: String? = nil,
        photoData: Data? = nil,
        transportDuration: String? = nil,
        iconName: String? = nil
    ) -> ItineraryItem {
        let item = ItineraryItem(context: context)
        let uuid = UUID()
        item.id = uuid
        item.type = type
        item.timestamp = timestamp
        item.title = title
        item.locationName = locationName
        item.price = price
        item.locationURL = locationURL
        item.memo = memo
        
        // Optimize: Save photo to file system instead of Core Data
        if let data = photoData {
            if ImageFileManager.shared.saveImage(data: data, for: uuid) {
                print("Image saved to file system for item: \(uuid)")
            }
            // Do NOT save to item.photoData to keep DB light
            item.photoData = nil 
        }
        
        item.transportDuration = transportDuration
        item.iconName = iconName
        
        save()
        return item
    }
    
    /// 取得所有行程項目，並依時間排序
    func fetchItems() -> [ItineraryItem] {
        let request: NSFetchRequest<ItineraryItem> = ItineraryItem.fetchRequest()
        let sort = NSSortDescriptor(key: "timestamp", ascending: true)
        request.sortDescriptors = [sort]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching items: \(error)")
            return []
        }
    }
    
    /// 刪除指定的行程項目
    func deleteItem(_ item: ItineraryItem) {
        // Also delete the image file if exists
        if let uuid = item.id {
            ImageFileManager.shared.deleteImage(for: uuid)
        }
        context.delete(item)
        save()
    }
    
    // MARK: - Migration (資料遷移)
    
    /// 將舊有的 CoreData 圖片遷移至檔案系統
    func migrateImagesToDisk() {
        let request: NSFetchRequest<ItineraryItem> = ItineraryItem.fetchRequest()
        
        do {
            let items = try context.fetch(request)
            var migratedCount = 0
            
            for item in items {
                // Check if item has heavy binary data in DB
                if let data = item.photoData, let uuid = item.id {
                    // Check if file already exists to avoid overwriting or duplicates
                    if !ImageFileManager.shared.imageExists(for: uuid) {
                        if ImageFileManager.shared.saveImage(data: data, for: uuid) {
                            // Clear DB field
                            item.photoData = nil
                            migratedCount += 1
                        }
                    } else {
                        // File exists, just clear DB
                        item.photoData = nil
                        migratedCount += 1 // Count as handled
                    }
                }
            }
            
            if migratedCount > 0 {
                save()
                print("Successfully migrated \(migratedCount) images to file system.")
            }
        } catch {
            print("Error during migration: \(error)")
        }
    }
}

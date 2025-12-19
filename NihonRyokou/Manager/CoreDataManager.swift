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
        item.id = UUID()
        item.type = type
        item.timestamp = timestamp
        item.title = title
        item.locationName = locationName
        item.price = price
        item.locationURL = locationURL
        item.memo = memo
        item.photoData = photoData
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
        context.delete(item)
        save()
    }
}

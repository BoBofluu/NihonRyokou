import Foundation
import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func createItem(type: String, timestamp: Date, title: String, locationName: String, price: Double, locationURL: String? = nil, memo: String? = nil, photoData: Data? = nil, transportDuration: String? = nil) -> ItineraryItem {
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
        
        save()
        return item
    }
    
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
    
    func deleteItem(_ item: ItineraryItem) {
        context.delete(item)
        save()
    }
}

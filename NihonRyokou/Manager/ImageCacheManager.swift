import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // NSCache for caching images in memory
    // Key: UUID (Item ID) or String (Image URL in future), Value: UIImage
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Set limits if needed, e.g., count limit or total cost limit
        cache.countLimit = 100 // Cache last 100 images
    }
    
    // Retrieve image from cache
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    // Save image to cache
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    // Clear cache (useful for low memory warnings)
    func clearCache() {
        cache.removeAllObjects()
    }
}

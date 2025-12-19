import UIKit

class ImageFileManager {
    
    static let shared = ImageFileManager()
    
    private let fileManager = FileManager.default
    private let directoryName = "ItineraryImages"
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getImagesDirectory() -> URL {
        return getDocumentsDirectory().appendingPathComponent(directoryName)
    }
    
    private func createDirectoryIfNeeded() {
        let directoryURL = getImagesDirectory()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating images directory: \(error)")
            }
        }
    }
    
    // MARK: - File Operations
    
    func saveImage(_ image: UIImage, for id: UUID) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = getImagesDirectory().appendingPathComponent("\(id.uuidString).jpg")
        
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }
    
    func saveImage(data: Data, for id: UUID) -> Bool {
        let fileURL = getImagesDirectory().appendingPathComponent("\(id.uuidString).jpg")
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image data: \(error)")
            return false
        }
    }
    
    func apppendImage(data: Data, for id: UUID) -> Bool {
        // Alias for saveImage(data:...) if needed, but saveImage is sufficient
        return saveImage(data: data, for: id)
    }
    
    func loadImage(for id: UUID) -> UIImage? {
        let fileURL = getImagesDirectory().appendingPathComponent("\(id.uuidString).jpg")
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }
    
    func deleteImage(for id: UUID) {
        let fileURL = getImagesDirectory().appendingPathComponent("\(id.uuidString).jpg")
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Error deleting image: \(error)")
            }
        }
    }
    
    func imageExists(for id: UUID) -> Bool {
        let fileURL = getImagesDirectory().appendingPathComponent("\(id.uuidString).jpg")
        return fileManager.fileExists(atPath: fileURL.path)
    }
}

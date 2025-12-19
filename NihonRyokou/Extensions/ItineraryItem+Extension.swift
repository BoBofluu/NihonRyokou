import Foundation

extension ItineraryItem {
    
    // Shared formatter for section headers
    private static let sectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Ensure fixed locale to avoid calendar discrepancies in sections
        formatter.locale = Locale(identifier: "en_US_POSIX") 
        return formatter
    }()
    
    /// Computed property for NSFetchedResultsController sectionNameKeyPath
    /// Groups items by Day
    @objc var sectionIdentifier: String {
        guard let date = timestamp else { return "9999-99-99" }
        return Self.sectionFormatter.string(from: date)
    }
}

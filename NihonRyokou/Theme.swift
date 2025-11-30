import UIKit

struct Theme {
    // Pastel / Cute Color Palette
    static let primaryColor = UIColor(red: 1.00, green: 0.98, blue: 0.96, alpha: 1.00) // Warm Cream
    static let accentColor = UIColor(red: 1.00, green: 0.60, blue: 0.70, alpha: 1.00) // Pastel Pink
    static let secondaryAccent = UIColor(red: 0.40, green: 0.70, blue: 1.00, alpha: 1.00) // Soft Blue
    static let textDark = UIColor(red: 0.30, green: 0.25, blue: 0.25, alpha: 1.00) // Warm Dark Gray
    static let textLight = UIColor(red: 0.60, green: 0.55, blue: 0.55, alpha: 1.00) // Warm Light Gray
    
    static let cornerRadius: CGFloat = 20.0
    
    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

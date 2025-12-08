import UIKit

struct Theme {
    // Pastel / Cute Color Palette
    static let primaryColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00) // Dark Gray
            : UIColor(red: 1.00, green: 0.98, blue: 0.96, alpha: 1.00) // Warm Cream
    }
    
    static let cardColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.00) // Secondary System Grouped
            : .white
    }
    
    static let inputFieldColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.23, green: 0.23, blue: 0.24, alpha: 1.00) // Tertiary System Grouped
            : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00) // Light Gray
    }
    
    static let transportCardColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.25, blue: 0.35, alpha: 1.00) // Dark Blue/Cyan
            : UIColor(red: 0.93, green: 0.97, blue: 1.00, alpha: 1.00) // Light Blue/Cyan
    }
    
    static let accentColor = UIColor(red: 1.00, green: 0.60, blue: 0.70, alpha: 1.00) // Pastel Pink
    static let secondaryAccent = UIColor(red: 0.40, green: 0.70, blue: 1.00, alpha: 1.00) // Soft Blue
    
    static let textDark = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.00) // Off-White
            : UIColor(red: 0.30, green: 0.25, blue: 0.25, alpha: 1.00) // Warm Dark Gray
    }
    
    static let textLight = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1.00) // Light Gray
            : UIColor(red: 0.60, green: 0.55, blue: 0.55, alpha: 1.00) // Warm Light Gray
    }
    
    static let cornerRadius: CGFloat = 20.0
    
    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

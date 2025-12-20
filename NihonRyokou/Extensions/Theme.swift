import UIKit

struct Theme {
    // Pastel / Cute Color Palette

    
    enum ThemeKey: String {
        case primaryColor
        case accentColor
        case transportCardColor
        case amountColor
        case transportCardTextColor // New key
    }
    
    // ...
    
    // Track the currently active preset name
    static var currentPresetName: String? {
        get { return UserDefaults.standard.string(forKey: "currentPresetName") }
        set { UserDefaults.standard.set(newValue, forKey: "currentPresetName") }
    }
    
    static var primaryColor: UIColor {
        return loadColor(for: .primaryColor) ?? UIColor(hex: "#FDF6E3") // Creamy White
    }
    
    static var accentColor: UIColor {
        return loadColor(for: .accentColor) ?? UIColor(hex: "#FF6F61") // Coral
    }
    
    static var secondaryAccent: UIColor {
        return UIColor(hex: "#FFD166") // Warm Yellow
    }
    
    static var cardColor: UIColor {
        // Dark Mode Override: Always Dark Gray Card
        if isDarkMode {
             return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00)
        }
        
        // Card color is now tied to the preset and not customizable individually
        if let presetName = currentPresetName,
           let preset = presets.first(where: { $0.name == presetName }) {
            return UIColor(hex: preset.card)
        }
        return UIColor(hex: "#FFFFFF") // Default White
    }
    
    static var transportCardColor: UIColor {
        return loadColor(for: .transportCardColor) ?? UIColor(hex: "#E3F2FD") // Light Blue
    }
    
    static var amountColor: UIColor {
        return loadColor(for: .amountColor) ?? UIColor(hex: "#FFD166") // Default to Warm Yellow (Secondary Accent)
    }
    
    // New: Transport Card Text Color Preference
    static var transportCardTextColor: UIColor {
        return loadColor(for: .transportCardTextColor) ?? textDark // Default to Dark Text
    }
    
    static var inputFieldColor: UIColor {
        return isDarkMode ? UIColor(white: 0.15, alpha: 1.0) : UIColor(hex: "#F5F5F5")
    }
    
    static var placeholderColor: UIColor {
        return isDarkMode ? UIColor.lightGray : UIColor.systemGray
    }
    
    // Designated color for background elements (Headers, Titles, etc.) that need to be white in Dark Mode
    // Also used for Card Titles if Card is dark
    static var cardTextColor: UIColor {
         return isDarkMode ? .white : textDark
    }
    
    static func saveColor(_ color: UIColor, for key: ThemeKey, isCustom: Bool = true) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: key.rawValue)
            
            // If this is a manual custom change, save it to the custom key as well
            if isCustom {
                UserDefaults.standard.set(data, forKey: "custom_\(key.rawValue)")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
    
    private static func loadColor(for key: ThemeKey) -> UIColor? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue),
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return nil
        }
        return color
    }
    
    // MARK: - Presets
    struct ThemePreset {
        let name: String
        let primary: String
        let accent: String
        let card: String
        let transport: String
        let amount: String
    }
    
    // Refined Presets - Light Mode Only
    static let presets: [ThemePreset] = [
        ThemePreset(name: "theme_custom", primary: "#FFFFFF", accent: "#CCCCCC", card: "#FFFFFF", transport: "#E0E0E0", amount: "#666666"), // Placeholder for Custom
        ThemePreset(name: "theme_sakura", primary: "#FFF0F5", accent: "#FF69B4", card: "#FFFFFF", transport: "#FFB7C5", amount: "#FF69B4"),
        ThemePreset(name: "theme_ocean", primary: "#E0F7FA", accent: "#00BCD4", card: "#FFFFFF", transport: "#B2EBF2", amount: "#00838F"),
        ThemePreset(name: "theme_matcha", primary: "#F1F8E9", accent: "#8BC34A", card: "#FFFFFF", transport: "#DCEDC8", amount: "#558B2F"),
        ThemePreset(name: "theme_sunset", primary: "#FFF3E0", accent: "#FF9800", card: "#FFFFFF", transport: "#FFE0B2", amount: "#E65100")
    ]
    
    static var isDarkMode: Bool {
        get { return UserDefaults.standard.bool(forKey: "isDarkMode") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
            
            // If we are currently in Custom Theme (or setting it), save this preference for Custom Theme specifically
            // This ensures if we switch to a Preset (Light) and come back, we remember this setting.
            if currentPresetName == "theme_custom" {
                UserDefaults.standard.set(newValue, forKey: "customThemeIsDarkMode")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
    
    static func applyPreset(_ preset: ThemePreset) {
        // Update name first so UI knows we are in preset mode
        currentPresetName = preset.name
        
        // Reset Dark Mode when applying a preset (presets are light)
        isDarkMode = false
        
        // When applying a preset, we are NOT making a custom change, so isCustom = false
        saveColor(UIColor(hex: preset.primary), for: .primaryColor, isCustom: false)
        saveColor(UIColor(hex: preset.accent), for: .accentColor, isCustom: false)
        saveColor(UIColor(hex: preset.transport), for: .transportCardColor, isCustom: false)
        saveColor(UIColor(hex: preset.amount), for: .amountColor, isCustom: false)
        // Reset Text Color to Dark (Default) for Presets
        saveColor(textDark, for: .transportCardTextColor, isCustom: false)
    }
    
    static func loadCustomTheme() {
        // Mark as custom theme first, so listeners know we are switching
        currentPresetName = "theme_custom"
        
        let keys: [ThemeKey] = [.primaryColor, .accentColor, .transportCardColor, .amountColor, .transportCardTextColor]
        
        for key in keys {
            if let data = UserDefaults.standard.data(forKey: "custom_\(key.rawValue)"),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                saveColor(color, for: key, isCustom: true)
            }
        }
        
        // Restore Dark Mode preference for Custom Theme
        // If it was never set, default to false (Light)
        let savedCustomDarkMode = UserDefaults.standard.bool(forKey: "customThemeIsDarkMode")
        isDarkMode = savedCustomDarkMode
    }
    
    // ... (Background Image and Icons methods remain unchanged)
    
    // MARK: - Background Image
    static var backgroundImage: UIImage? {
        guard let data = UserDefaults.standard.data(forKey: "backgroundImage") else { return nil }
        return UIImage(data: data)
    }
    
    static func saveBackgroundImage(_ image: UIImage?) {
        if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "backgroundImage")
        } else {
            UserDefaults.standard.removeObject(forKey: "backgroundImage")
        }
        NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    // MARK: - Custom Icons
    static func getIcon(for category: String) -> UIImage? {
        let key = "customIcon_\(category)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return UIImage(data: data)
    }
    
    static func saveIcon(_ image: UIImage, for category: String) {
        let key = "customIcon_\(category)"
        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: key)
        }
        NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    static func resetIcon(for category: String) {
        let key = "customIcon_\(category)"
        UserDefaults.standard.removeObject(forKey: key)
        NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    static let textDark = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.00)
    
    static let textLight = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1.00)
    
    // Designated color for background elements (Headers, Titles, etc.) that need to be white in Dark Mode
    static var backgroundTextColor: UIColor {
        return isDarkMode ? .white : textDark
    }
    
    // Helper to determine if a color is light or dark
    static func isLight(color: UIColor) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        return luminance > 0.5
    }
    
    static let cornerRadius: CGFloat = 20.0
    
    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

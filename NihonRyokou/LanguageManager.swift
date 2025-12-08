import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "selectedLanguage"
    
    enum Language: String, CaseIterable {
        case english = "en"
        case chinese = "zh-Hant"
        case korean = "ko"
        case japanese = "ja"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "繁體中文"
            case .korean: return "한국어"
            case .japanese: return "日本語"
            }
        }
    }
    
    var currentLanguage: Language {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: languageKey),
               let lang = Language(rawValue: rawValue) {
                return lang
            }
            return .japanese
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
        }
    }
    
    func localizedString(_ key: String) -> String {
        var bundle = Bundle.main
        
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        }
        
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    var currentLocale: Locale {
        return Locale(identifier: currentLanguage.rawValue)
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
}

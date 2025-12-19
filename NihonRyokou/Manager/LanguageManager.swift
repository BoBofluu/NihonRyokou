import Foundation

class LanguageManager {
    
    // MARK: - Singleton (單例模式)
    
    static let shared = LanguageManager()
    
    private let languageKey = "selectedLanguage"
    
    // MARK: - Language Enum (語言枚舉)
    
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
    
    // MARK: - Properties (屬性)
    
    /// 當前選擇的語言
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
    
    /// 當前的 Locale 設定
    var currentLocale: Locale {
        return Locale(identifier: currentLanguage.rawValue)
    }
    
    // MARK: - Localization (本地化)
    
    /// 取得本地化字串
    /// - Parameter key: 本地化鍵值
    /// - Returns: 對應語言的字串
    func localizedString(_ key: String) -> String {
        var bundle = Bundle.main
        
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        }
        
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}

// MARK: - String Extension (字串擴展)

extension String {
    /// 快速取得本地化字串
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
}

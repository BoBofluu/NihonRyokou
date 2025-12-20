import UIKit
import Then
import SnapKit

class LanguageSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "language_section_title".localized
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc private func updateTheme() {
        view.backgroundColor = Theme.primaryColor
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = Theme.cardColor
        cell.textLabel?.textColor = Theme.backgroundTextColor
        
        let languages = ["English", "日本語", "繁體中文", "한국어"]
        cell.textLabel?.text = languages[indexPath.row]
        
        let currentLang = LanguageManager.shared.currentLanguage
        let isSelected = (indexPath.row == 0 && currentLang == .english) ||
                         (indexPath.row == 1 && currentLang == .japanese) ||
                         (indexPath.row == 2 && currentLang == .chinese) ||
                         (indexPath.row == 3 && currentLang == .korean)
        
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedLanguage: LanguageManager.Language
        switch indexPath.row {
        case 0: selectedLanguage = .english
        case 1: selectedLanguage = .japanese
        case 2: selectedLanguage = .chinese
        case 3: selectedLanguage = .korean
        default: return
        }
        
        LanguageManager.shared.currentLanguage = selectedLanguage
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        
        // Reload Root VC to apply language change globally
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.reloadRootViewController()
        }
        
        tableView.reloadData()
    }
}

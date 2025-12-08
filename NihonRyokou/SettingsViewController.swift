import UIKit
import Then
import SnapKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = Theme.primaryColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTexts()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func updateTexts() {
        title = "settings_title".localized
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LanguageManager.Language.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "language_setting".localized
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let language = LanguageManager.Language.allCases[indexPath.row]
        
        cell.textLabel?.text = language.displayName
        cell.textLabel?.font = Theme.font(size: 16, weight: .medium)
        cell.backgroundColor = Theme.cardColor
        
        if language == LanguageManager.shared.currentLanguage {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = Theme.accentColor
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = Theme.textDark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedLanguage = LanguageManager.Language.allCases[indexPath.row]
        LanguageManager.shared.currentLanguage = selectedLanguage
        
        // Reload App
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.reloadRootViewController()
        }
    }
}

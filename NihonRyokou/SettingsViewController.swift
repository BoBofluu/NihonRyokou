import UIKit
import Then
import SnapKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let backgroundImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private enum SettingOption: Int, CaseIterable {
        case language
        case appearance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "settings_title".localized
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc private func updateTheme() {
        view.backgroundColor = Theme.primaryColor
        
        if let bgImage = Theme.backgroundImage {
            backgroundImageView.image = bgImage
            backgroundImageView.isHidden = false
        } else {
            backgroundImageView.isHidden = true
        }
        
        // Update Navigation Bar
        if let navBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.titleTextAttributes = [.foregroundColor: Theme.textDark]
            appearance.largeTitleTextAttributes = [.foregroundColor: Theme.textDark]
            appearance.shadowColor = .clear // Remove divider line
            
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
            
            navBar.tintColor = Theme.accentColor // Back Button
        }
        
        setNeedsStatusBarAppearanceUpdate()
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.isLight(color: Theme.primaryColor) ? .darkContent : .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTheme()
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingOption.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let cellBackground = Theme.backgroundImage != nil ? Theme.cardColor.withAlphaComponent(0.9) : Theme.cardColor
        cell.backgroundColor = cellBackground
        
        // Calculate text color based on Card Color brightness, not Primary Color
        let isCardLight = Theme.isLight(color: Theme.cardColor)
        // If card is light, text should be dark. If card is dark, text white.
        // We use a dedicated logic here instead of Theme.textDark
        cell.textLabel?.textColor = isCardLight ? UIColor(white: 0.2, alpha: 1.0) : UIColor(white: 0.95, alpha: 1.0)
        
        cell.accessoryType = .disclosureIndicator
        
        let option = SettingOption(rawValue: indexPath.row)
        switch option {
        case .language:
            cell.textLabel?.text = "language_section_title".localized
            cell.imageView?.image = UIImage(systemName: "globe")
        case .appearance:
            cell.textLabel?.text = "appearance_section_title".localized
            cell.imageView?.image = UIImage(systemName: "paintbrush.fill")
        default: break
        }
        
        cell.imageView?.tintColor = Theme.accentColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let option = SettingOption(rawValue: indexPath.row)
        switch option {
        case .language:
            let vc = LanguageSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .appearance:
            let vc = AppearanceSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
}

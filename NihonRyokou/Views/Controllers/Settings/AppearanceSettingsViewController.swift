import UIKit
import Then
import SnapKit

class AppearanceSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIColorPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Sections
    private enum Section: Int, CaseIterable {
        case presets
        case background
        case customColors
        case actions
    }
    
    // Custom Color Options
    private enum ColorOption: Int, CaseIterable {
        case primaryColor
        case accentColor // Restore accentColor
        case transportCardColor
        case transportCardTextColor
        case amountColor
    }
    
    // Icon Categories
    
    private var selectedThemeKey: Theme.ThemeKey?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "appearance_section_title".localized
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(ThemePresetCell.self, forCellReuseIdentifier: "PresetCell")

        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc private func updateTheme() {
        view.backgroundColor = Theme.primaryColor
        // Update Navigation Bar
        if let navBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.titleTextAttributes = [.foregroundColor: Theme.backgroundTextColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: Theme.backgroundTextColor]
            appearance.shadowColor = .clear
            
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance // For iPhone landscape
            
            navBar.tintColor = Theme.accentColor
        }
        
        setNeedsStatusBarAppearanceUpdate()
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.isLight(color: Theme.primaryColor) ? .darkContent : .lightContent
    }
    
    // MARK: - TableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = Section(rawValue: section)
        switch sectionType {
        case .presets: return 1
        case .background: return 1 // Image only
        case .customColors: return ColorOption.allCases.count + 1 // +1 for Dark Mode Toggle
        case .actions:
             // Only show action if NOT using custom theme
             if let current = Theme.currentPresetName, current != "theme_custom" {
                 return 1
             }
             return 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = Section(rawValue: section)
        switch sectionType {
        case .presets:
            let title = "theme_presets_title".localized
            if let current = Theme.currentPresetName {
                 return "\(title): \(current.localized)"
            }
            return title
        case .background: return "background_image".localized
        case .customColors: return "custom_colors_title".localized
        case .actions: return nil
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = Theme.backgroundTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = Section(rawValue: indexPath.section)
        
        if sectionType == .presets {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PresetCell", for: indexPath) as! ThemePresetCell
            cell.configure(presets: Theme.presets)
            cell.onPresetSelected = { [weak self] preset in
                if preset.name == "theme_custom" {
                    Theme.loadCustomTheme()
                } else {
                    Theme.applyPreset(preset)
                }
                self?.tableView.reloadData()
            }
            cell.backgroundColor = .clear
            return cell
        } else if sectionType == .background {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            // Reset reused state
            cell.contentView.alpha = 1.0
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textAlignment = .natural
            
            let textKey = Theme.backgroundImage == nil ? "select_background_image" : "change_background_image"
            cell.textLabel?.text = textKey.localized
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = Theme.cardColor
            
            // Text Color based on Card Contrast
            // Use Theme.backgroundTextColor for Dark Mode support (White in Dark Mode)
            cell.textLabel?.textColor = Theme.backgroundTextColor
            
            cell.imageView?.image = nil
            cell.accessoryView = nil
            return cell
            
        } else if sectionType == .customColors {
            // Need to handle both color options and dark mode switch
            // Logic: rows 0-3 are colors, row 4 is Dark Mode Switch
            
            if indexPath.row < ColorOption.allCases.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.backgroundColor = Theme.cardColor
                cell.textLabel?.textAlignment = .natural
                
                // Text Color based on Card Contrast
                // Use Theme.backgroundTextColor
                // If Custom Colors section has a white background (cardColor), and we are in Dark Mode (isDarkMode=true),
                // Theme.backgroundTextColor will be WHITE.
                // Wait, if Card is White, White Text is invisible.
                // Theme.cardColor handles this: In Dark Mode, cardColor is Dark Gray.
                // So text should indeed be White (Theme.backgroundTextColor).
                // In Light Mode, cardColor is typically White (preset). Text should be Dark.
                // Theme.backgroundTextColor handles this too (returns textDark if !isDarkMode).
                
                cell.textLabel?.textColor = Theme.backgroundTextColor
                
                cell.imageView?.image = nil
                cell.accessoryView = nil
                cell.accessoryType = .none
                
                let option = ColorOption(rawValue: indexPath.row)
                switch option {
                case .primaryColor:
                    cell.textLabel?.text = "primary_color_option".localized
                    addColorPreview(to: cell, color: Theme.primaryColor)
                case .accentColor:
                    cell.textLabel?.text = "accent_color_option".localized
                    addColorPreview(to: cell, color: Theme.accentColor)
                case .transportCardColor:
                    cell.textLabel?.text = "transport_card_color_option".localized
                    addColorPreview(to: cell, color: Theme.transportCardColor)
                case .transportCardTextColor:
                    cell.textLabel?.text = "transport_card_text_color_option".localized
                    
                    let segment = UISegmentedControl(items: ["text_color_dark".localized, "text_color_light".localized])
                    // Use symbols if localization fails or as enhancement? 
                    // No, user requested Multi-language, so localized text is best.
                    
                    segment.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
                    
                    // Check current value
                    // Note: Theme.transportCardTextColor returns a Color. 
                    // We need to compare specific values.
                    // But wait, the default might be textDark (0.2, 0.2, 0.2).
                    // .black is (0,0,0). .white is (1,1,1).
                    // Let's check brightness.
                    let isLightText = Theme.isLight(color: Theme.transportCardTextColor)
                    segment.selectedSegmentIndex = isLightText ? 1 : 0
                    
                    segment.addTarget(self, action: #selector(didChangeTransportTextColor(_:)), for: .valueChanged)
                    cell.accessoryView = segment
                    
                case .amountColor:
                    cell.textLabel?.text = "amount_color_option".localized
                    addColorPreview(to: cell, color: Theme.amountColor)
                default: break
                }
                
                // Disable editing if not Custom Theme
                let isCustom = Theme.currentPresetName == "theme_custom"
                
                // Special handling for the switch/segment interaction
                cell.isUserInteractionEnabled = isCustom
                if let segment = cell.accessoryView as? UISegmentedControl {
                    segment.isEnabled = isCustom
                }
                
                cell.contentView.alpha = isCustom ? 1.0 : 0.5
                cell.backgroundColor = isCustom ? Theme.cardColor : UIColor.systemGray6
                
                return cell
            } else {
                // Dark Mode Row
                let cell = UITableViewCell(style: .default, reuseIdentifier: "SwitchCell")
                cell.backgroundColor = Theme.cardColor
                cell.contentView.alpha = (Theme.currentPresetName == "theme_custom") ? 1.0 : 0.5
                cell.isUserInteractionEnabled = (Theme.currentPresetName == "theme_custom")
                if !cell.isUserInteractionEnabled { cell.backgroundColor = UIColor.systemGray6 }
                
                cell.textLabel?.text = "dark_mode_option".localized
                cell.textLabel?.textColor = Theme.backgroundTextColor
                cell.selectionStyle = .none
                
                let switchView = UISwitch()
                switchView.isOn = Theme.isDarkMode
                switchView.onTintColor = Theme.accentColor
                switchView.addTarget(self, action: #selector(didToggleDarkMode(_:)), for: .valueChanged)
                // Disable switch if not custom theme
                switchView.isEnabled = (Theme.currentPresetName == "theme_custom")
                
                cell.accessoryView = switchView
                return cell
            }
            
        } else if sectionType == .actions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            // Reset reused state
            cell.contentView.alpha = 1.0
            cell.isUserInteractionEnabled = true
            
            cell.backgroundColor = Theme.cardColor
            
            cell.textLabel?.text = "overwrite_custom_theme".localized
            // Standard text color (Black/Dark) as requested
            cell.textLabel?.textColor = Theme.textDark 
            cell.textLabel?.textAlignment = .center
            
            cell.imageView?.image = nil
            cell.accessoryView = nil
            cell.accessoryType = .none
            
            return cell
        }
        return UITableViewCell()
    }

    
    private func addColorPreview(to cell: UITableViewCell, color: UIColor) {
        let preview = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        preview.backgroundColor = color
        preview.layer.cornerRadius = 12
        preview.layer.borderWidth = 1
        preview.layer.borderColor = UIColor.systemGray4.cgColor
        cell.accessoryView = preview
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionType = Section(rawValue: indexPath.section)
        
        if sectionType == .background {
            if Theme.backgroundImage != nil {
                let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                sheet.addAction(UIAlertAction(title: "change_background_image".localized, style: .default) { [weak self] _ in
                    self?.showImagePicker()
                })
                sheet.addAction(UIAlertAction(title: "delete_photo".localized, style: .destructive) { [weak self] _ in
                    Theme.saveBackgroundImage(nil)
                    self?.tableView.reloadData()
                })
                sheet.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
                
                // For iPad
                if let cell = tableView.cellForRow(at: indexPath) {
                    sheet.popoverPresentationController?.sourceView = cell
                    sheet.popoverPresentationController?.sourceRect = cell.bounds
                }
                
                present(sheet, animated: true)
            } else {
                showImagePicker()
            }

        } else if sectionType == .customColors {
            let option = ColorOption(rawValue: indexPath.row)
            switch option {
            case .primaryColor: selectedThemeKey = .primaryColor
            case .accentColor: selectedThemeKey = .accentColor
            case .transportCardColor: selectedThemeKey = .transportCardColor
            case .amountColor: selectedThemeKey = .amountColor
            default: return
            }
            showColorPicker()
            
        } else if sectionType == .actions {
            // Overwrite Custom Theme
            let alert = UIAlertController(title: "overwrite_custom_theme_alert_title".localized, message: "overwrite_custom_theme_alert_message".localized, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "action_overwrite".localized, style: .default) { [weak self] _ in
                self?.handleOverwriteCustomTheme()
            })
            
            present(alert, animated: true)
        }
    }
    
    private func handleOverwriteCustomTheme() {
        // Save current colors to Custom Theme keys
        Theme.saveColor(Theme.primaryColor, for: .primaryColor)
        Theme.saveColor(Theme.accentColor, for: .accentColor)
        Theme.saveColor(Theme.transportCardColor, for: .transportCardColor)
        Theme.saveColor(Theme.amountColor, for: .amountColor)
        
        // Switch to Custom Theme explicitly
        Theme.loadCustomTheme()
        
        // Reload UI
        tableView.reloadData()
        
        // Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc private func didChangeTransportTextColor(_ sender: UISegmentedControl) {
        let isLight = sender.selectedSegmentIndex == 1
        Theme.saveColor(isLight ? .white : .black, for: .transportCardTextColor)
    }

    @objc private func didToggleDarkMode(_ sender: UISwitch) {
        Theme.isDarkMode = sender.isOn
        // Update UI
        tableView.reloadData()
    }

    
    // MARK: - Image Picker
    private func showImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        
        // Only for background image now
        Theme.saveBackgroundImage(image)
        tableView.reloadData()
    }
    
    // MARK: - Color Picker
    private func showColorPicker() {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        
        if let key = selectedThemeKey {
            switch key {
            case .primaryColor: picker.selectedColor = Theme.primaryColor
            case .accentColor: picker.selectedColor = Theme.accentColor
            case .transportCardColor: picker.selectedColor = Theme.transportCardColor
            case .amountColor: picker.selectedColor = Theme.amountColor
            case .transportCardTextColor: picker.selectedColor = Theme.transportCardTextColor
            }
        }
        
        present(picker, animated: true)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        guard let key = selectedThemeKey else { return }
        Theme.saveColor(viewController.selectedColor, for: key)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
}



// MARK: - Theme Preset Cell
class ThemePresetCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var onPresetSelected: ((Theme.ThemePreset) -> Void)?
    private var presets: [Theme.ThemePreset] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(PresetItemCell.self, forCellWithReuseIdentifier: "PresetItemCell")
        return cv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(110).priority(999)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(presets: [Theme.ThemePreset]) {
        self.presets = presets
        collectionView.reloadData()
        
        // Scroll to selected if possible (optional, maybe too jumping)
        // But definitely need to reload to show correct border
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PresetItemCell", for: indexPath) as! PresetItemCell
        cell.configure(with: presets[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onPresetSelected?(presets[indexPath.item])
    }
}

class PresetItemCell: UICollectionViewCell {
    
    private let colorView = UIView().then {
        $0.layer.cornerRadius = 30
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }
    
    private let nameLabel = UILabel().then {
        $0.font = Theme.font(size: 12, weight: .medium)
        $0.textColor = Theme.backgroundTextColor
        $0.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
        contentView.addSubview(nameLabel)
        
        colorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(colorView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with preset: Theme.ThemePreset) {
        colorView.backgroundColor = UIColor(hex: preset.primary)
        colorView.layer.borderColor = UIColor(hex: preset.accent).cgColor
        nameLabel.text = preset.name.localized
        nameLabel.textColor = Theme.backgroundTextColor // Ensure color updates on reload
        
        if Theme.currentPresetName == preset.name {
            colorView.layer.borderWidth = 4
            colorView.layer.borderColor = Theme.accentColor.cgColor
            colorView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } else {
            colorView.layer.borderWidth = 2
            colorView.layer.borderColor = UIColor.white.cgColor
            colorView.transform = .identity
        }
    }
}

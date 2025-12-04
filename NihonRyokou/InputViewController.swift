import UIKit

class InputViewController: UIViewController {
    
    var onSave: (() -> Void)?
    
    // 主容器：卡片式背景
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = Theme.accentColor.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = [
            "transport".localized,
            "hotel".localized,
            "restaurant".localized
        ]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    // MARK: - Date Picker 區域 (修改重點)
    
    // 1. 建立一個灰色圓角容器 (Wrapper)，讓日期選擇器看起來像一個欄位
    private let dateInputWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 淺灰背景
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 2. 左側的日曆 Icon
    private let dateIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = Theme.textLight
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // 3. 原生 DatePicker (.compact 風格 = 彈跳視窗)
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .compact // 保持您喜歡的彈跳視窗
        dp.tintColor = Theme.accentColor
        dp.locale = Locale.current
        dp.translatesAutoresizingMaskIntoConstraints = false
        // 讓內容靠左，貼近我們的 Icon
        dp.contentHorizontalAlignment = .leading
        return dp
    }()
    
    // MARK: - 其他輸入欄位
    
    private func createCuteTextField(placeholder: String, keyboardType: UIKeyboardType = .default, iconName: String? = nil) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = Theme.font(size: 16, weight: .medium)
        tf.textColor = Theme.textDark
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        tf.layer.cornerRadius = 12
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = .none
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 50))
        if let iconName = iconName {
            let iconImageView = UIImageView(image: UIImage(systemName: iconName))
            iconImageView.tintColor = Theme.textLight
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.frame = CGRect(x: 12, y: 15, width: 20, height: 20)
            leftPaddingView.addSubview(iconImageView)
        } else {
            leftPaddingView.frame = CGRect(x: 0, y: 0, width: 16, height: 50)
        }
        
        tf.leftView = leftPaddingView
        tf.leftViewMode = .always
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }
    
    private lazy var titleField = createCuteTextField(placeholder: "Title", iconName: "pencil")
    private lazy var locationField = createCuteTextField(placeholder: "Location", iconName: "mappin.and.ellipse")
    private lazy var priceField = createCuteTextField(placeholder: "Price", keyboardType: .numberPad, iconName: "yensign.circle")
    private lazy var urlField = createCuteTextField(placeholder: "URL", iconName: "link")
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("add_button_title".localized, for: .normal)
        btn.backgroundColor = Theme.accentColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = Theme.font(size: 18, weight: .bold)
        btn.layer.cornerRadius = 28
        btn.layer.shadowColor = Theme.accentColor.cgColor
        btn.layer.shadowOpacity = 0.4
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "add_item_title".localized
        
        setupUI()
        setupActions()
        setupKeyboardToolbar()
        segmentChanged()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // 價格鍵盤加上 Done 按鈕
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneBtn], animated: true)
        
        priceField.inputAccessoryView = toolbar
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(segmentedControl)
        
        // 將 DatePicker 放入 Wrapper 中
        containerView.addSubview(dateInputWrapper)
        dateInputWrapper.addSubview(dateIconView)
        dateInputWrapper.addSubview(datePicker)
        
        containerView.addSubview(titleField)
        containerView.addSubview(locationField)
        containerView.addSubview(priceField)
        containerView.addSubview(urlField)
        view.addSubview(saveButton)
        
        let fieldHeight: CGFloat = 50
        let spacing: CGFloat = 20
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // --- Date Wrapper 佈局 ---
            // 讓它長得跟下面的 TextField 一樣高、一樣寬
            dateInputWrapper.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: spacing),
            dateInputWrapper.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dateInputWrapper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            dateInputWrapper.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // Icon 位置
            dateIconView.leadingAnchor.constraint(equalTo: dateInputWrapper.leadingAnchor, constant: 12),
            dateIconView.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor),
            dateIconView.widthAnchor.constraint(equalToConstant: 20),
            dateIconView.heightAnchor.constraint(equalToConstant: 20),
            
            // DatePicker 位置：靠左對齊 Icon，垂直置中
            datePicker.leadingAnchor.constraint(equalTo: dateIconView.trailingAnchor, constant: 12),
            datePicker.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor),
            // 不設 trailing，讓它自然延伸，避免被拉伸
            // -----------------------
            
            titleField.topAnchor.constraint(equalTo: dateInputWrapper.bottomAnchor, constant: spacing),
            titleField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            locationField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            locationField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            locationField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            locationField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            priceField.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 16),
            priceField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            priceField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            priceField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            urlField.topAnchor.constraint(equalTo: priceField.bottomAnchor, constant: 16),
            urlField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            urlField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            urlField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            urlField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            
            saveButton.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func segmentChanged() {
        let index = segmentedControl.selectedSegmentIndex
        switch index {
        case 0: titleField.placeholder = "title_placeholder_transport".localized
        case 1: titleField.placeholder = "title_placeholder_hotel".localized
        case 2: titleField.placeholder = "title_placeholder_restaurant".localized
        default: titleField.placeholder = "title_placeholder_default".localized
        }
        
        locationField.placeholder = "location_placeholder".localized
        priceField.placeholder = "price_placeholder".localized
        urlField.placeholder = "url_placeholder".localized
    }
    
    @objc private func handleSave() {
        guard let title = titleField.text, !title.isEmpty else { return }
        let price = Double(priceField.text ?? "") ?? 0.0
        
        let type: String
        switch segmentedControl.selectedSegmentIndex {
        case 0: type = "transport"
        case 1: type = "hotel"
        case 2: type = "restaurant"
        default: type = "other"
        }
        
        let urlString = urlField.text?.isEmpty == false ? urlField.text : nil
        
        _ = CoreDataManager.shared.createItem(
            type: type,
            timestamp: datePicker.date, // 直接取用 DatePicker 的值
            title: title,
            locationName: locationField.text ?? "",
            price: price,
            locationURL: urlString
        )
        
        onSave?()
        
        titleField.text = ""
        locationField.text = ""
        priceField.text = ""
        urlField.text = ""
        datePicker.date = Date() // 重置時間
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: nil, message: "Added! ✨", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
}

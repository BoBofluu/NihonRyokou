import UIKit

class InputViewController: UIViewController {
    
    var onSave: (() -> Void)?
    
    // 主容器：加大陰影與圓角
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24 // 更圓
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
    
    // 日期選擇器容器 (為了美化背景)
    private let dateContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.primaryColor // 淡色背景
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = Theme.accentColor
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()
    
    // 輔助函式：建立可愛風格的輸入框
    private func createCuteTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .none // 移除預設邊框，自己畫
        tf.backgroundColor = UIColor(white: 0.96, alpha: 1.0) // 淺灰背景
        tf.layer.cornerRadius = 12 // 圓角
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = .none
        
        // 增加左側內距
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: tf.frame.height))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }
    
    // 使用 lazy var 搭配輔助函式建立欄位
    private lazy var titleField = createCuteTextField(placeholder: "Title")
    private lazy var locationField = createCuteTextField(placeholder: "Location")
    private lazy var priceField = createCuteTextField(placeholder: "Price", keyboardType: .numberPad) // 限制數字輸入
    private lazy var urlField = createCuteTextField(placeholder: "URL")
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("add_button_title".localized, for: .normal)
        btn.backgroundColor = Theme.accentColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = Theme.font(size: 18, weight: .bold)
        btn.layer.cornerRadius = 28 // 變成膠囊形狀
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
        segmentChanged() // 初始化文字
        
        // 點擊背景收起鍵盤
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(segmentedControl)
        
        containerView.addSubview(dateContainer)
        dateContainer.addSubview(datePicker)
        
        containerView.addSubview(titleField)
        containerView.addSubview(locationField)
        containerView.addSubview(priceField)
        containerView.addSubview(urlField)
        
        view.addSubview(saveButton)
        
        let fieldHeight: CGFloat = 50 // 加高輸入框
        let spacing: CGFloat = 24 // 加大間距
        
        NSLayoutConstraint.activate([
            // 容器
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // 分頁控制
            segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // 日期區塊
            dateContainer.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: spacing),
            dateContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dateContainer.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            dateContainer.heightAnchor.constraint(equalToConstant: 40),
            
            datePicker.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            datePicker.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor, constant: 8),
            datePicker.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor, constant: -8),
            
            // 輸入欄位 (加大間距)
            titleField.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: spacing),
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
            
            urlField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30), // 底部留白
            
            // 儲存按鈕 (懸浮在容器下方)
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
            timestamp: datePicker.date,
            title: title,
            locationName: locationField.text ?? "",
            price: price,
            locationURL: urlString
        )
        
        onSave?()
        
        // 清空欄位
        titleField.text = ""
        locationField.text = ""
        priceField.text = ""
        urlField.text = ""
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: nil, message: "Added! ✨", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
}

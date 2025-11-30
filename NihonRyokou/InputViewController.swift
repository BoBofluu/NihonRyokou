import UIKit

class InputViewController: UIViewController {
    
    var onSave: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Theme.cornerRadius
        // 加強陰影效果，更立體
        view.layer.shadowColor = Theme.accentColor.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
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
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .compact
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()
    
    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Title"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let locationField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Location"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let priceField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Price (JPY)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let urlField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "URL (Optional)"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("add_button_title".localized, for: .normal)
        btn.backgroundColor = Theme.accentColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = Theme.font(size: 18, weight: .bold)
        btn.layer.cornerRadius = 25
        btn.layer.shadowColor = Theme.accentColor.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "add_item_title".localized
        
        setupUI()
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentChanged() // Initial state
        
        // 點擊背景收起鍵盤
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(segmentedControl)
        containerView.addSubview(datePicker)
        containerView.addSubview(titleField)
        containerView.addSubview(locationField)
        containerView.addSubview(priceField)
        containerView.addSubview(urlField)
        view.addSubview(saveButton)
        
        let fieldHeight: CGFloat = 44
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            datePicker.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            titleField.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
            titleField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            locationField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 12),
            locationField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            locationField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            locationField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            priceField.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 12),
            priceField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            priceField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            priceField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            urlField.topAnchor.constraint(equalTo: priceField.bottomAnchor, constant: 12),
            urlField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            urlField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            urlField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 讓 Container 包住所有內容
            urlField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func segmentChanged() {
            // 修正：所有選項都要可以輸入 URL，所以不再設定 urlField.isHidden
            let index = segmentedControl.selectedSegmentIndex
            
            switch index {
            case 0: // Transport
                titleField.placeholder = "title_placeholder_transport".localized
            case 1: // Hotel
                titleField.placeholder = "title_placeholder_hotel".localized
            case 2: // Restaurant
                titleField.placeholder = "title_placeholder_restaurant".localized
            default:
                titleField.placeholder = "title_placeholder_default".localized
            }
            
            locationField.placeholder = "location_placeholder".localized
            priceField.placeholder = "price_placeholder".localized
            urlField.placeholder = "url_placeholder".localized // 確保這行會執行
            
            // 如果您之前的程式碼有 urlField.isHidden = ... 請務必移除
            urlField.isHidden = false
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
        
        // 確保 URL 字串有值才傳入
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
        
        // 簡單的成功震動回饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 使用系統原生的 Alert 或 Toast 提示
        let alert = UIAlertController(title: nil, message: "Added successfully! ✨", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
}

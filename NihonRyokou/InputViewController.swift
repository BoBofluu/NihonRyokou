import UIKit
import PhotosUI

class InputViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var onSave: (() -> Void)?
    private var selectedImageData: Data?
    
    // 用來控制照片區塊高度的約束
    private var photoContainerHeightConstraint: NSLayoutConstraint?
    
    // 主容器
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
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let scrollContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = [
            "transport".localized,
            "hotel".localized,
            "restaurant".localized,
            "activity".localized
        ]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    // MARK: - Date Picker
    
    private let dateInputWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = Theme.textLight
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = Theme.accentColor
        dp.locale = Locale.current
        dp.translatesAutoresizingMaskIntoConstraints = false
        dp.contentHorizontalAlignment = .leading
        return dp
    }()
    
    // MARK: - Photo Area
    
    private let photoContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var photoButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "camera.fill")
        config.title = " Photo"
        config.baseForegroundColor = Theme.textDark
        config.background.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        config.cornerStyle = .medium
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapPhotoButton), for: .touchUpInside)
        return btn
    }()
    
    private lazy var photoPreview: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPreviewImage))
        iv.addGestureRecognizer(tap)
        
        return iv
    }()
    
    // MARK: - Input Fields
    
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
    
    private lazy var titleField = createCuteTextField(placeholder: "title_placeholder_default".localized, iconName: "pencil")
    private lazy var locationField = createCuteTextField(placeholder: "location_placeholder".localized, iconName: "mappin.and.ellipse")
    private lazy var memoField = createCuteTextField(placeholder: "Memo", iconName: "note.text")
    private lazy var priceField = createCuteTextField(placeholder: "price_placeholder".localized, keyboardType: .numberPad, iconName: "yensign.circle")
    private lazy var urlField = createCuteTextField(placeholder: "url_placeholder".localized, iconName: "link")
    
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
        containerView.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        
        // 加入所有元件
        [segmentedControl, dateInputWrapper, titleField, locationField, memoField, priceField, urlField, photoContainer, saveButton].forEach {
            scrollContentView.addSubview($0)
        }
        
        dateInputWrapper.addSubview(dateIconView)
        dateInputWrapper.addSubview(datePicker)
        
        photoContainer.addSubview(photoButton)
        photoContainer.addSubview(photoPreview)
        
        let fieldHeight: CGFloat = 50
        let spacing: CGFloat = 20
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // ScrollContentView
            scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 1. Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // 2. Date
            dateInputWrapper.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            dateInputWrapper.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            dateInputWrapper.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            dateInputWrapper.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            dateIconView.leadingAnchor.constraint(equalTo: dateInputWrapper.leadingAnchor, constant: 12),
            dateIconView.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor),
            dateIconView.widthAnchor.constraint(equalToConstant: 20),
            dateIconView.heightAnchor.constraint(equalToConstant: 20),
            
            datePicker.leadingAnchor.constraint(equalTo: dateIconView.trailingAnchor, constant: 12),
            datePicker.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor),
            
            // 3. Title
            titleField.topAnchor.constraint(equalTo: dateInputWrapper.bottomAnchor, constant: spacing),
            titleField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 4. Location
            locationField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            locationField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            locationField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            locationField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 5. Memo
            memoField.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 16),
            memoField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            memoField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            memoField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 6. Price
            priceField.topAnchor.constraint(equalTo: memoField.bottomAnchor, constant: 16),
            priceField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            priceField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            priceField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 7. URL
            urlField.topAnchor.constraint(equalTo: priceField.bottomAnchor, constant: 16),
            urlField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            urlField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            urlField.heightAnchor.constraint(equalToConstant: fieldHeight),
            
            // 8. Photo Container
            photoContainer.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 20),
            photoContainer.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 20),
            photoContainer.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -20),
            // Height is managed by photoContainerHeightConstraint
            
            photoButton.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor),
            photoButton.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 120),
            photoButton.heightAnchor.constraint(equalToConstant: 50),
            
            photoPreview.leadingAnchor.constraint(equalTo: photoButton.trailingAnchor, constant: 16),
            photoPreview.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            photoPreview.widthAnchor.constraint(equalToConstant: 50),
            photoPreview.heightAnchor.constraint(equalToConstant: 50),
            
            // 9. Save Button (修正：加入陣列中)
            saveButton.topAnchor.constraint(equalTo: photoContainer.bottomAnchor, constant: 30),
            saveButton.centerXAnchor.constraint(equalTo: scrollContentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -20)
        ])
        
        // 額外啟用照片區塊的高度約束
        photoContainerHeightConstraint = photoContainer.heightAnchor.constraint(equalToConstant: 60)
        photoContainerHeightConstraint?.isActive = true
    }
    
    // MARK: - Logic
    @objc private func segmentChanged() {
        let index = segmentedControl.selectedSegmentIndex
        
        // 交通 (0) -> 隱藏照片; 其他 -> 顯示
        if index == 0 {
            photoContainer.isHidden = true
            photoContainerHeightConstraint?.constant = 0
            photoButton.alpha = 0
        } else {
            photoContainer.isHidden = false
            photoContainerHeightConstraint?.constant = 60
            photoButton.alpha = 1
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        // Placeholder
        switch index {
        case 0: titleField.placeholder = "title_placeholder_transport".localized
        case 1: titleField.placeholder = "title_placeholder_hotel".localized
        case 2: titleField.placeholder = "title_placeholder_restaurant".localized
        case 3: titleField.placeholder = "activity".localized
        default: titleField.placeholder = "title_placeholder_default".localized
        }
    }
    
    // MARK: - Photo Actions
    @objc private func didTapPhotoButton() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let self = self, let image = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self.photoPreview.image = image
                    self.photoPreview.isHidden = false
                    self.selectedImageData = image.jpegData(compressionQuality: 0.7)
                }
            }
        }
    }
    
    @objc private func didTapPreviewImage() {
        guard let image = photoPreview.image else { return }
        let previewVC = UIViewController()
        previewVC.view.backgroundColor = .black
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        previewVC.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: previewVC.view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: previewVC.view.safeAreaLayoutGuide.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: previewVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: previewVC.view.trailingAnchor)
        ])
        present(previewVC, animated: true)
    }
    
    // MARK: - Save Logic
    @objc private func handleSave() {
        guard let title = titleField.text, !title.isEmpty else {
            showAlert(message: "alert_title_empty".localized)
            return
        }
        
        let priceText = priceField.text ?? ""
        var price: Double = 0.0
        if !priceText.isEmpty {
            guard let validPrice = Double(priceText) else {
                showAlert(message: "alert_price_invalid".localized)
                return
            }
            price = validPrice
        }
        
        var urlString: String? = nil
        if let text = urlField.text, !text.isEmpty {
            let lowerText = text.lowercased()
            if !lowerText.hasPrefix("https://") && !lowerText.hasPrefix("http://") {
                showAlert(message: "alert_url_invalid".localized)
                return
            }
            urlString = text
        }
        
        let type: String
        switch segmentedControl.selectedSegmentIndex {
        case 0: type = "transport"
        case 1: type = "hotel"
        case 2: type = "restaurant"
        case 3: type = "activity"
        default: type = "other"
        }
        
        _ = CoreDataManager.shared.createItem(
            type: type,
            timestamp: datePicker.date,
            title: title,
            locationName: locationField.text ?? "",
            price: price,
            locationURL: urlString,
            memo: memoField.text,
            photoData: selectedImageData
        )
        
        onSave?()
        
        // Reset
        titleField.text = ""
        locationField.text = ""
        priceField.text = ""
        urlField.text = ""
        memoField.text = ""
        selectedImageData = nil
        photoPreview.image = nil
        photoPreview.isHidden = true
        datePicker.date = Date()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: nil, message: "alert_added_message".localized, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "alert_error_title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok_action".localized, style: .default))
        present(alert, animated: true)
    }
}

// 確保其他檔案 (CoreDataManager) 中 createItem 方法簽名有加上 memo 和 photoData，否則這裡會報錯。
// 這裡補充 Extension 避免 UIViewController.dismissModal 報錯 (若之前沒加)
extension UIViewController {
    @objc func dismissPreview() {
        dismiss(animated: true)
    }
}

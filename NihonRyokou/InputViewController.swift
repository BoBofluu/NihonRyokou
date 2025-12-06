import UIKit
import PhotosUI

class InputViewController: UIViewController, PHPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var onSave: (() -> Void)?
    private var selectedImageData: Data?
    
    
    
    private let hours = Array(0...24)
    private let minutes = Array(0...59)
    private var selectedHour = 0
    private var selectedMinute = 0
    
    // MARK: - UI Components
    
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
    
    private let formStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        sc.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return sc
    }()
    
    // MARK: - Date Picker
    private let dateInputWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
    
    // MARK: - Duration Picker
    private lazy var durationPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    // MARK: - Photo Area
    private let photoContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var photoButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "camera.fill")
        config.title = "photo_button".localized
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
    
    private lazy var photoDeleteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("delete_photo".localized, for: .normal)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.titleLabel?.font = Theme.font(size: 14, weight: .medium)
        btn.backgroundColor = .clear
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        btn.addTarget(self, action: #selector(didTapDeletePhoto), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Input Fields Helper
    private func createCuteTextField(placeholder: String, keyboardType: UIKeyboardType = .default, iconName: String? = nil, hasHeightConstraint: Bool = true) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = Theme.font(size: 16, weight: .medium)
        tf.textColor = Theme.textDark
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        tf.layer.cornerRadius = 12
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        if hasHeightConstraint {
            // 一般欄位固定 50 高
            tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
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
        return tf
    }
    
    // MARK: - Fields Definition
    private lazy var titleField = createCuteTextField(placeholder: "title_placeholder_default".localized, iconName: "pencil")
    private lazy var durationField = createCuteTextField(placeholder: "travel_time_placeholder".localized, iconName: "clock")
    private lazy var locationField = createCuteTextField(placeholder: "location_placeholder".localized, iconName: "mappin.and.ellipse")
    private lazy var memoField = createCuteTextField(placeholder: "memo_placeholder".localized, iconName: "note.text")
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
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "add_item_title".localized
        
        setupUI()
        setupActions()
        setupKeyboardToolbar()
        durationField.inputView = durationPicker
        durationField.delegate = self
        durationField.tintColor = .clear
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
        durationField.inputAccessoryView = toolbar
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    // MARK: - Layout
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(formStackView)
        
        // 1. Date Picker
        dateInputWrapper.addSubview(dateIconView)
        dateInputWrapper.addSubview(datePicker)
        NSLayoutConstraint.activate([
            dateIconView.leadingAnchor.constraint(equalTo: dateInputWrapper.leadingAnchor, constant: 12),
            dateIconView.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor),
            dateIconView.widthAnchor.constraint(equalToConstant: 20),
            dateIconView.heightAnchor.constraint(equalToConstant: 20),
            datePicker.leadingAnchor.constraint(equalTo: dateIconView.trailingAnchor, constant: 12),
            datePicker.centerYAnchor.constraint(equalTo: dateInputWrapper.centerYAnchor)
        ])
        
        // 2. Photo Container
        photoContainer.addSubview(photoButton)
        photoContainer.addSubview(photoPreview)
        photoContainer.addSubview(photoDeleteButton)
        NSLayoutConstraint.activate([
            photoButton.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor),
            photoButton.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 120),
            photoButton.heightAnchor.constraint(equalToConstant: 50),
            
            photoPreview.leadingAnchor.constraint(equalTo: photoButton.trailingAnchor, constant: 16),
            photoPreview.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            photoPreview.widthAnchor.constraint(equalToConstant: 50),
            photoPreview.heightAnchor.constraint(equalToConstant: 50),
            
            photoDeleteButton.leadingAnchor.constraint(equalTo: photoPreview.trailingAnchor, constant: 12),
            photoDeleteButton.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            photoDeleteButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 3. Add to StackView
        let items = [
            segmentedControl,
            dateInputWrapper,
            titleField,
            durationField,
            locationField,
            memoField,
            priceField,
            urlField,
            photoContainer,
            saveButton
        ]
        items.forEach { formStackView.addArrangedSubview($0) }
        
        formStackView.setCustomSpacing(30, after: photoContainer)
        
        photoContainer.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // 6. Main Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            formStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            formStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            formStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            formStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            formStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    // MARK: - Logic
    @objc private func segmentChanged() {
        let index = segmentedControl.selectedSegmentIndex
        
        switch index {
        case 0: titleField.placeholder = "title_placeholder_transport".localized
        case 1: titleField.placeholder = "title_placeholder_hotel".localized
        case 2: titleField.placeholder = "title_placeholder_restaurant".localized
        case 3: titleField.placeholder = "activity".localized
        default: titleField.placeholder = "title_placeholder_default".localized
        }
        
        if index == 0 {
            durationField.isHidden = false
            photoContainer.isHidden = true
        } else {
            durationField.isHidden = true
            photoContainer.isHidden = false
        }
        
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 2 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return component == 0 ? hours.count : minutes.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? "\(hours[row]) \("hour".localized)" : "\(minutes[row]) \("minute".localized)"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 { selectedHour = hours[row] } else { selectedMinute = minutes[row] }
        updateDurationText()
    }
    private func updateDurationText() {
        if selectedHour == 0 && selectedMinute == 0 { durationField.text = "" }
        else if selectedHour == 0 { durationField.text = "\(selectedMinute)\("minute".localized)" }
        else if selectedMinute == 0 { durationField.text = "\(selectedHour)\("hour".localized)" }
        else { durationField.text = "\(selectedHour)\("hour".localized) \(selectedMinute)\("minute".localized)" }
    }
    
    @objc private func didTapPhotoButton() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func didTapDeletePhoto() {
        selectedImageData = nil
        photoPreview.image = nil
        photoPreview.isHidden = true
        photoDeleteButton.isHidden = true
        photoButton.isHidden = false
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let self = self, let originalImage = image as? UIImage else { return }
                let resizedImage = self.resizeImage(image: originalImage, targetWidth: 800)
                DispatchQueue.main.async {
                    self.photoPreview.image = resizedImage
                    self.photoPreview.isHidden = false
                    self.photoDeleteButton.isHidden = false
                    self.selectedImageData = resizedImage.jpegData(compressionQuality: 0.7)
                }
            }
        }
    }
    
    private func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage {
        let size = image.size
        let widthRatio  = targetWidth  / size.width
        let newSize = CGSize(width: targetWidth, height: size.height * widthRatio)
        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    @objc private func didTapPreviewImage() {
        guard let image = photoPreview.image else { return }
        let previewVC = UIViewController()
        previewVC.view.backgroundColor = .black
        previewVC.modalPresentationStyle = .fullScreen
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let closeBtn = UIButton(type: .close)
        closeBtn.tintColor = .white
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addAction(UIAction { _ in previewVC.dismiss(animated: true) }, for: .touchUpInside)
        previewVC.view.addSubview(imageView)
        previewVC.view.addSubview(closeBtn)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: previewVC.view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: previewVC.view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: previewVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: previewVC.view.trailingAnchor),
            closeBtn.topAnchor.constraint(equalTo: previewVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: previewVC.view.trailingAnchor, constant: -16)
        ])
        present(previewVC, animated: true)
    }
    
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
            if validPrice > 9_999_999_999 {
                showAlert(message: "alert_price_too_high".localized)
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
            photoData: (type == "transport") ? nil : selectedImageData,
            transportDuration: (type == "transport") ? durationField.text : nil
        )
        onSave?()
        resetFields()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        let alert = UIAlertController(title: nil, message: "alert_added_message".localized, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
    
    private func resetFields() {
        titleField.text = ""
        locationField.text = ""
        priceField.text = ""
        urlField.text = ""
        memoField.text = ""
        durationField.text = ""
        selectedImageData = nil
        photoPreview.image = nil
        photoPreview.isHidden = true
        photoDeleteButton.isHidden = true
        photoButton.isHidden = false

        selectedHour = 0
        selectedMinute = 0
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "alert_error_title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok_action".localized, style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == durationField {
            return false
        }
        return true
    }
}

import UIKit
import PhotosUI
import Then
import SnapKit

class InputViewController: UIViewController, PHPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var onSave: (() -> Void)?
    private var selectedImageData: Data?
    
    private let hours = Array(0...24)
    private let minutes = Array(0...59)
    private var selectedHour = 0
    private var selectedMinute = 0
    
    // MARK: - UI Components (UI 元件)
    
    // 主要容器視圖，包含陰影效果
    private let containerView = UIView().then {
        $0.backgroundColor = Theme.cardColor
        $0.layer.cornerRadius = 24
        $0.layer.shadowColor = Theme.accentColor.cgColor
        $0.layer.shadowOpacity = 0.15
        $0.layer.shadowOffset = CGSize(width: 0, height: 8)
        $0.layer.shadowRadius = 12
    }
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let formStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    private let segmentedControl = UISegmentedControl(items: [
        "transport".localized,
        "hotel".localized,
        "restaurant".localized,
        "activity".localized
    ]).then {
        $0.selectedSegmentIndex = 0
    }
    
    // MARK: - Date Picker
    private let dateInputWrapper = UIView().then {
        $0.backgroundColor = Theme.inputFieldColor
        $0.layer.cornerRadius = 12
    }
    
    private let dateIconView = UIImageView(image: UIImage(systemName: "calendar")).then {
        $0.tintColor = Theme.textLight
        $0.contentMode = .scaleAspectFit
    }
    
    private let datePicker = UIDatePicker().then {
        $0.datePickerMode = .dateAndTime
        $0.preferredDatePickerStyle = .compact
        $0.tintColor = Theme.accentColor
        $0.locale = Locale.current
        $0.contentHorizontalAlignment = .leading
    }
    
    // MARK: - Duration Picker
    private lazy var durationPicker = UIPickerView().then {
        $0.delegate = self
        $0.dataSource = self
    }
    
    // MARK: - Photo Area
    private let photoContainer = UIView().then {
        $0.backgroundColor = .clear
        $0.clipsToBounds = true
    }
    
    private lazy var photoButton = UIButton(type: .system).then {
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "camera.fill")
        config.title = "photo_button".localized
        config.baseForegroundColor = Theme.textDark
        config.background.backgroundColor = Theme.inputFieldColor
        config.cornerStyle = .medium
        $0.configuration = config
        $0.addTarget(self, action: #selector(didTapPhotoButton), for: .touchUpInside)
    }
    
    private lazy var photoPreview = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = Theme.inputFieldColor
        $0.isHidden = true
        $0.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPreviewImage))
        $0.addGestureRecognizer(tap)
    }
    
    private lazy var photoDeleteButton = UIButton(type: .system).then {
        $0.setTitle("delete_photo".localized, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = Theme.font(size: 14, weight: .medium)
        $0.backgroundColor = .clear
        $0.isHidden = true
        $0.addTarget(self, action: #selector(didTapDeletePhoto), for: .touchUpInside)
    }
    
    // MARK: - Input Fields Helper (輸入欄位輔助方法)
    
    // 建立帶有圖示的可愛風格輸入框
    private func createCuteTextField(placeholder: String, keyboardType: UIKeyboardType = .default, iconName: String? = nil, hasHeightConstraint: Bool = true) -> UITextField {
        let tf = UITextField().then {
            $0.placeholder = placeholder
            $0.font = Theme.font(size: 16, weight: .medium)
            $0.textColor = Theme.textDark
            $0.borderStyle = .none
            $0.backgroundColor = Theme.inputFieldColor
            $0.layer.cornerRadius = 12
            $0.keyboardType = keyboardType
            $0.autocapitalizationType = .none
        }
        
        if hasHeightConstraint {
            tf.snp.makeConstraints { make in
                make.height.equalTo(50).priority(999)
            }
        }
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 50))
        if let iconName = iconName {
            let iconImageView = UIImageView(image: UIImage(systemName: iconName)).then {
                $0.tintColor = Theme.textLight
                $0.contentMode = .scaleAspectFit
                $0.frame = CGRect(x: 12, y: 15, width: 20, height: 20)
            }
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
    
    private lazy var saveButton = UIButton(type: .system).then {
        $0.setTitle("add_button_title".localized, for: .normal)
        $0.backgroundColor = Theme.accentColor
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = Theme.font(size: 18, weight: .bold)
        $0.layer.cornerRadius = 28
        $0.layer.shadowColor = Theme.accentColor.cgColor
        $0.layer.shadowOpacity = 0.4
        $0.layer.shadowOffset = CGSize(width: 0, height: 4)
        $0.layer.shadowRadius = 8
        $0.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "add_item_title".localized
        
        setupUI()
        setupKeyboardToolbar()
        durationField.inputView = durationPicker
        durationField.delegate = self
        durationField.tintColor = .clear
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentChanged()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar().then {
            $0.sizeToFit()
        }
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneBtn], animated: true)
        
        priceField.inputAccessoryView = toolbar
        durationField.inputAccessoryView = toolbar
    }
    
    // MARK: - Layout
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(formStackView)
        
        // 1. Date Picker
        dateInputWrapper.addSubview(dateIconView)
        dateInputWrapper.addSubview(datePicker)
        
        dateIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        datePicker.snp.makeConstraints { make in
            make.leading.equalTo(dateIconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        dateInputWrapper.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        // 2. Photo Container
        photoContainer.addSubview(photoButton)
        photoContainer.addSubview(photoPreview)
        photoContainer.addSubview(photoDeleteButton)
        
        photoButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.width.equalTo(120)
            make.height.equalTo(50).priority(999)
        }
        
        photoPreview.snp.makeConstraints { make in
            make.leading.equalTo(photoButton.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        photoDeleteButton.snp.makeConstraints { make in
            make.leading.equalTo(photoPreview.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }
        
        // 3. Add to StackView
        [segmentedControl, dateInputWrapper, titleField, durationField, locationField, memoField, priceField, urlField, photoContainer, saveButton].forEach {
            formStackView.addArrangedSubview($0)
        }
        
        formStackView.setCustomSpacing(30, after: photoContainer)
        
        segmentedControl.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        
        // 6. Main Constraints
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        
        formStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalToSuperview().offset(-40)
        }
    }
    
    // MARK: - Logic (邏輯處理)
    
    // 當類別選擇改變時，更新 UI 狀態
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
    
    // 點擊照片按鈕，開啟照片選擇器
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
    
    // 調整圖片大小以節省記憶體
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
        let imageView = UIImageView(image: image).then {
            $0.contentMode = .scaleAspectFit
        }
        let closeBtn = UIButton(type: .close).then {
            $0.tintColor = .white
            $0.addAction(UIAction { _ in previewVC.dismiss(animated: true) }, for: .touchUpInside)
        }
        previewVC.view.addSubview(imageView)
        previewVC.view.addSubview(closeBtn)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(previewVC.view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        present(previewVC, animated: true)
    }
    
    // 處理儲存按鈕點擊事件
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

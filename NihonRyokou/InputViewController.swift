import UIKit

class InputViewController: UIViewController {
    
    var onSave: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Theme.cornerRadius
        view.layer.shadowColor = Theme.accentColor.cgColor
        view.layer.shadowOpacity = 0.1
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
        tf.placeholder = "Title (e.g. Tokyo Station)"
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
        btn.layer.cornerRadius = 25 // Fully rounded pill shape
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
        
        let fieldHeight: CGFloat = 50
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            datePicker.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            titleField.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
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
            urlField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func segmentChanged() {
        let index = segmentedControl.selectedSegmentIndex
        if index == 0 { // Transport
            urlField.isHidden = false
            titleField.placeholder = "title_placeholder_transport".localized
        } else {
            urlField.isHidden = true
            if index == 1 {
                titleField.placeholder = "title_placeholder_hotel".localized
            } else {
                titleField.placeholder = "title_placeholder_restaurant".localized
            }
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
        
        _ = CoreDataManager.shared.createItem(
            type: type,
            timestamp: datePicker.date,
            title: title,
            locationName: locationField.text ?? "",
            price: price,
            locationURL: urlField.text
        )
        
        onSave?()
        
        // Clear fields and show success feedback
        titleField.text = ""
        locationField.text = ""
        priceField.text = ""
        urlField.text = ""
        
        let alert = UIAlertController(title: "Success", message: "Item added!", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true)
        }
    }
}

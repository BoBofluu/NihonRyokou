import UIKit
import WebKit
import Then
import SnapKit

class DetailViewController: UIViewController {
    
    private let item: ItineraryItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private lazy var imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        $0.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        $0.addGestureRecognizer(tap)
    }
    
    private func createSelectableTextView(font: UIFont, color: UIColor) -> UITextView {
        return UITextView().then {
            $0.font = font
            $0.textColor = color
            $0.isEditable = false
            $0.isScrollEnabled = false
            $0.backgroundColor = .clear
            $0.textContainerInset = .zero
            $0.textContainer.lineFragmentPadding = 0
            $0.dataDetectorTypes = .link // Enable links
            $0.isUserInteractionEnabled = true
        }
    }

    private lazy var titleLabel = createSelectableTextView(font: Theme.font(size: 24, weight: .bold), color: Theme.textDark)
    
    private lazy var locationLabel = createSelectableTextView(font: Theme.font(size: 16, weight: .medium), color: .systemGray)
    
    // 修改：改為垂直堆疊，靠左對齊
    private let infoStack = UIStackView().then {
        $0.axis = .vertical // 垂直
        $0.alignment = .leading // 靠左
        $0.distribution = .fill
        $0.spacing = 8 // 稍微縮小間距
    }
    
    private lazy var timeLabel = createSelectableTextView(font: Theme.font(size: 16, weight: .medium), color: Theme.textLight)
    
    private lazy var priceLabel = createSelectableTextView(font: Theme.font(size: 20, weight: .bold), color: Theme.secondaryAccent)
    
    private lazy var memoLabel = createSelectableTextView(font: Theme.font(size: 16, weight: .regular), color: Theme.textDark)
    
    private lazy var webView = WKWebView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        // Add border for separation
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    init(item: ItineraryItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        title = "detail_title".localized
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "edit-1")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(didTapEdit))
        navigationItem.rightBarButtonItem?.tintColor = .systemBlue
        
        setupUI()
        configureData()
    }
    
    @objc private func didTapEdit() { print("Edit button tapped") }
    
    @objc private func didTapImage() {
        guard let image = imageView.image else { return }
        let previewVC = ImagePreviewViewController(image: image)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(locationLabel)
        
        infoStack.addArrangedSubview(timeLabel)
        infoStack.addArrangedSubview(priceLabel)
        contentView.addSubview(infoStack)
        
        contentView.addSubview(memoLabel)
        contentView.addSubview(webView)
        
        let padding: CGFloat = 20
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(padding)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }
        
        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }
        
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(36) // Increased padding for map
            make.trailing.equalToSuperview().offset(-36) // Increased padding for map
            make.height.equalTo(500)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    private func configureData() {
        titleLabel.text = item.title
        
        if let loc = item.locationName, !loc.isEmpty {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "mappin.and.ellipse")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
            attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
            let completeText = NSMutableAttributedString(attachment: attachment)
            completeText.append(NSAttributedString(string: " " + loc))
            locationLabel.attributedText = completeText
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
            locationLabel.text = nil
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm"
        
        if let date = item.timestamp {
            timeLabel.text = formatter.string(from: date)
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        if item.price > 0 {
            priceLabel.isHidden = false
            if let priceString = numberFormatter.string(from: NSNumber(value: item.price)) {
                priceLabel.text = "¥\(priceString)"
            } else {
                priceLabel.text = "¥\(Int(item.price))"
            }
        } else {
            priceLabel.isHidden = true
            priceLabel.text = nil
        }
        
        memoLabel.text = item.memo ?? ""
        
        let uuid = item.id ?? UUID()
        let cacheKey = uuid.uuidString
        
        imageView.isHidden = true
        var imageToDisplay: UIImage?
        
        // 1. Check Memory Cache
        if let cachedImage = ImageCacheManager.shared.image(forKey: cacheKey) {
            imageToDisplay = cachedImage
        }
        // 2. Check File System
        else if let fileImage = ImageFileManager.shared.loadImage(for: uuid) {
            imageToDisplay = fileImage
            ImageCacheManager.shared.setImage(fileImage, forKey: cacheKey)
        }
        // 3. Fallback to Core Data (Legacy Support)
        else if let data = item.photoData, let dbImage = UIImage(data: data) {
            imageToDisplay = dbImage
            ImageCacheManager.shared.setImage(dbImage, forKey: cacheKey)
        }
        
        if let image = imageToDisplay {
            imageView.image = image
            imageView.isHidden = false
            imageView.snp.updateConstraints { make in
                make.height.equalTo(300)
            }
        } else {
            imageView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
        
        if let urlStr = item.locationURL, let url = URL(string: urlStr) {
            if urlStr.lowercased().contains("google") || urlStr.lowercased().contains("goo.gl") || urlStr.lowercased().contains("maps") {
                webView.isHidden = false
                let request = URLRequest(url: url)
                webView.load(request)
                webView.snp.updateConstraints { make in
                    make.height.equalTo(500)
                }
            } else {
                webView.isHidden = true
                webView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
            }
        } else {
            webView.isHidden = true
            webView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }
}

class ImagePreviewViewController: UIViewController {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Add Pan Gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc private func listSelf() { dismiss(animated: true) } // Typo correction in original was dismissSelf, keeping consistent logic
    @objc private func dismissSelf() { dismiss(animated: true) }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let velocity = sender.velocity(in: view)
        
        switch sender.state {
        case .changed:
            // Move view with drag
            view.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            
            // Fade background based on vertical distance
            let progress = abs(translation.y) / view.bounds.height
            view.backgroundColor = UIColor.black.withAlphaComponent(1 - min(progress * 2, 0.8))
            
        case .ended:
            // Dismiss if dragged far enough or fast enough downwards
            if translation.y > 100 || velocity.y > 500 {
                dismiss(animated: true)
            } else {
                // Reset
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity
                    self.view.backgroundColor = .black
                }
            }
            
        default:
            break
        }
    }
}



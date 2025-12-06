import UIKit
import WebKit

class DetailViewController: UIViewController {
    
    private let item: ItineraryItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 1. 照片
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        iv.addGestureRecognizer(tap)
        return iv
    }()
    
    // 2. 標題
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 24, weight: .bold)
        label.numberOfLines = 0
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 3. 地點 (新增)
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .medium)
        label.textColor = .systemGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 4. 時間與價格的容器 (解決重疊問題)
    private let infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .firstBaseline // 讓文字基線對齊
        stack.distribution = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .medium)
        label.textColor = Theme.textLight
        label.numberOfLines = 0 // 允許換行
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 20, weight: .bold)
        label.textColor = Theme.secondaryAccent
        // 抗壓縮優先級設高，確保價格不被擠壓
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    // 5. 備註
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .regular)
        label.numberOfLines = 0
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 6. 地圖
    private lazy var webView: WKWebView = {
        let web = WKWebView()
        web.translatesAutoresizingMaskIntoConstraints = false
        web.layer.cornerRadius = 12
        web.clipsToBounds = true
        web.backgroundColor = .systemGray6
        return web
    }()
    
    init(item: ItineraryItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Details"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(didTapEdit))
        
        setupUI()
        configureData()
    }
    
    @objc private func didTapEdit() {
        // 編輯功能預留
    }
    
    @objc private func didTapImage() {
        guard let image = imageView.image else { return }
        let previewVC = ImagePreviewViewController(image: image)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 依序加入元件
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(locationLabel)
        
        // 將 Time 和 Price 加入 Stack
        infoStack.addArrangedSubview(timeLabel)
        infoStack.addArrangedSubview(priceLabel)
        contentView.addSubview(infoStack)
        
        contentView.addSubview(memoLabel)
        contentView.addSubview(webView)
        
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // 1. Photo
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            // 2. Title
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // 3. Location (新增)
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // 4. Info Stack (Time + Price)
            infoStack.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 12),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // 5. Memo
            memoLabel.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 24),
            memoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            memoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // 6. Map
            webView.topAnchor.constraint(equalTo: memoLabel.bottomAnchor, constant: 24),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            webView.heightAnchor.constraint(equalToConstant: 500), // 兩倍大
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func configureData() {
        titleLabel.text = item.title
        
        // ... (保留地點顯示邏輯)
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
        
        // 修改：詳情頁價格防呆
        let priceString = String(format: "%.0f", item.price)
        priceLabel.text = "¥\(priceString)"
        
        memoLabel.text = item.memo ?? ""
        
        // ... (保留後續圖片與地圖邏輯)
        if let data = item.photoData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
            imageView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        
        if let urlStr = item.locationURL, let url = URL(string: urlStr) {
            if urlStr.lowercased().contains("google") || urlStr.lowercased().contains("goo.gl") || urlStr.lowercased().contains("maps") {
                webView.isHidden = false
                let request = URLRequest(url: url)
                webView.load(request)
            } else {
                webView.isHidden = true
                webView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            }
        } else {
            webView.isHidden = true
            webView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
    }
}

// 圖片預覽器 (維持不變)
class ImagePreviewViewController: UIViewController {
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .close)
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(imageView)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    @objc private func dismissSelf() { dismiss(animated: true) }
}

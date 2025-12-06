import UIKit
import WebKit

class DetailViewController: UIViewController {
    
    private let item: ItineraryItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 24, weight: .bold)
        label.numberOfLines = 0
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .medium)
        label.textColor = .systemGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 修改：改為垂直堆疊，靠左對齊
    private let infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical // 垂直
        stack.alignment = .leading // 靠左
        stack.distribution = .fill
        stack.spacing = 8 // 稍微縮小間距
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
        label.numberOfLines = 0
        label.textAlignment = .left // 改為靠左
        return label
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .regular)
        label.numberOfLines = 0
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Details"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(didTapEdit))
        
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
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(locationLabel)
        
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
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            infoStack.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 12),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            memoLabel.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 24),
            memoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            memoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            webView.topAnchor.constraint(equalTo: memoLabel.bottomAnchor, constant: 24),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            webView.heightAnchor.constraint(equalToConstant: 500),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
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
        
        if let priceString = numberFormatter.string(from: NSNumber(value: item.price)) {
            priceLabel.text = "¥\(priceString)"
        } else {
             priceLabel.text = "¥\(Int(item.price))"
        }
        
        memoLabel.text = item.memo ?? ""
        
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

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
    
    private let titleLabel = UILabel().then {
        $0.font = Theme.font(size: 24, weight: .bold)
        $0.numberOfLines = 0
        $0.textColor = Theme.textDark
    }
    
    private let locationLabel = UILabel().then {
        $0.font = Theme.font(size: 16, weight: .medium)
        $0.textColor = .systemGray
        $0.numberOfLines = 0
    }
    
    // 修改：改為垂直堆疊，靠左對齊
    private let infoStack = UIStackView().then {
        $0.axis = .vertical // 垂直
        $0.alignment = .leading // 靠左
        $0.distribution = .fill
        $0.spacing = 8 // 稍微縮小間距
    }
    
    private let timeLabel = UILabel().then {
        $0.font = Theme.font(size: 16, weight: .medium)
        $0.textColor = Theme.textLight
        $0.numberOfLines = 0 // 允許換行
    }
    
    private let priceLabel = UILabel().then {
        $0.font = Theme.font(size: 20, weight: .bold)
        $0.textColor = Theme.secondaryAccent
        $0.numberOfLines = 0
        $0.textAlignment = .left // 改為靠左
    }
    
    private let memoLabel = UILabel().then {
        $0.font = Theme.font(size: 16, weight: .regular)
        $0.numberOfLines = 0
        $0.textColor = Theme.textDark
    }
    
    private lazy var webView = WKWebView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }
    
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
        
        title = "detail_title".localized
        
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
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
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
        
        if let priceString = numberFormatter.string(from: NSNumber(value: item.price)) {
            priceLabel.text = "¥\(priceString)"
        } else {
            priceLabel.text = "¥\(Int(item.price))"
        }
        
        memoLabel.text = item.memo ?? ""
        
        if let data = item.photoData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.isHidden = false
            imageView.snp.updateConstraints { make in
                make.height.equalTo(300)
            }
        } else {
            imageView.isHidden = true
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
    
    private let closeButton = UIButton(type: .close).then {
        $0.tintColor = .white
        $0.addTarget(ImagePreviewViewController.self, action: #selector(dismissSelf), for: .touchUpInside)
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
        view.addSubview(closeButton)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }
    @objc private func dismissSelf() { dismiss(animated: true) }
}

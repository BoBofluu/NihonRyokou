import UIKit

class ItineraryCell: UITableViewCell {
    
    static let identifier = "ItineraryCell"
    var onDelete: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Theme.cornerRadius
        view.layer.shadowColor = Theme.accentColor.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 時間改為置中
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = Theme.accentColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .semibold)
        label.textColor = Theme.textDark
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 新增：右側照片 (正方形)
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "trash", withConfiguration: config), for: .normal)
        btn.tintColor = .systemGray4
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func deleteButtonTapped() { onDelete?() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(photoImageView) // Add photo
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Time: Vertically Center
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            timeLabel.widthAnchor.constraint(equalToConstant: 45),
            
            // Icon
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Photo: Right side, Square
            photoImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            photoImageView.widthAnchor.constraint(equalToConstant: 40),
            photoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            // Title 右邊界貼著 Photo 的左邊
            titleLabel.trailingAnchor.constraint(equalTo: photoImageView.leadingAnchor, constant: -8),
            
            // Delete Button (放在 Photo 上面或旁邊? 為了佈局乾淨，我們放右下角，或者可以跟 Photo 重疊，這裡我先微調讓它不擋住主要資訊)
            // 這裡為了簡化，我讓 deleteButton 覆蓋在最右側邊緣，或者您可以選擇長按刪除
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
        ])
    }
    
    func configure(with item: ItineraryItem) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = item.timestamp.map { formatter.string(from: $0) } ?? "--:--"
        titleLabel.text = item.title
        
        // 設定 Icon
        let imageName: String
        switch item.type {
        case "transport": imageName = "tram.fill"
        case "hotel": imageName = "bed.double.fill"
        case "restaurant": imageName = "fork.knife"
        default: imageName = "mappin.circle.fill"
        }
        iconView.image = UIImage(systemName: imageName)
        
        // 交通類型的特殊樣式
        if item.type == "transport" {
            containerView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0) // 淡藍色區隔
            iconView.tintColor = Theme.secondaryAccent
        } else {
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
        }
        
        // 顯示照片
        if let data = item.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.isHidden = false
        } else {
            photoImageView.isHidden = true
        }
    }
}

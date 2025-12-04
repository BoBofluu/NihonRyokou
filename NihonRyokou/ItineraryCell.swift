import UIKit

class ItineraryCell: UITableViewCell {
    
    static let identifier = "ItineraryCell"
    
    // 新增：刪除按鈕被點擊時的 Callback
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
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .regular)
        label.textColor = Theme.textLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 14, weight: .medium)
        label.textColor = Theme.secondaryAccent
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let linkHintLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .regular)
        label.textColor = .systemBlue
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 新增：實體刪除按鈕 (垃圾桶 Icon)
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "trash", withConfiguration: config), for: .normal)
        btn.tintColor = .systemGray4 // 淺灰色，不要太搶眼
        btn.translatesAutoresizingMaskIntoConstraints = false
        // 增加點擊範圍
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        
        // 綁定按鈕事件
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(locationLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(linkHintLabel)
        containerView.addSubview(deleteButton) // 加入按鈕
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            timeLabel.widthAnchor.constraint(equalToConstant: 45),
            
            iconView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 4),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),
            
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),
            
            priceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // 刪除按鈕固定在右下角
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // 連結提示改放在刪除按鈕的左邊
            linkHintLabel.centerYAnchor.constraint(equalTo: deleteButton.centerYAnchor),
            linkHintLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -4),
            linkHintLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20)
        ])
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if selectionStyle != .none {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
    
    func configure(with item: ItineraryItem) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = item.timestamp {
            timeLabel.text = formatter.string(from: date)
        } else {
            timeLabel.text = "--:--"
        }
        
        titleLabel.text = item.title
        locationLabel.text = item.locationName
        priceLabel.text = "¥\(Int(item.price))"
        
        let imageName: String
        switch item.type {
        case "transport": imageName = "tram.fill"
        case "hotel": imageName = "bed.double.fill"
        case "restaurant": imageName = "fork.knife"
        default: imageName = "mappin.circle.fill"
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconView.image = UIImage(systemName: imageName, withConfiguration: config)
        iconView.tintColor = item.type == "transport" ? Theme.secondaryAccent : Theme.accentColor
        
        if let urlStr = item.locationURL, !urlStr.isEmpty {
            linkHintLabel.text = "Link 🔗"
            linkHintLabel.isHidden = false
            self.selectionStyle = .default
        } else {
            linkHintLabel.isHidden = true
            self.selectionStyle = .none
        }
    }
}

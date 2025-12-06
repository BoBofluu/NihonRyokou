import UIKit

class ItineraryCell: UITableViewCell {
    
    static let identifier = "ItineraryCell"
    
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
    
    // 主 Stack：[Icon, TitleStack, Spacer, AccessoryStack]
    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        // 固定 Icon 大小
        iv.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return iv
    }()
    
    // 中間：標題 + 備註
    private let titleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .semibold)
        label.textColor = Theme.textDark
        label.numberOfLines = 1
        return label
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 1
        return label
    }()
    
    // 右側區域：[價格Stack, 照片]
    private let accessoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    // 價格 + 移動時間 (垂直排列)
    private let priceInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .trailing // 靠右對齊
        stack.spacing = 2
        return stack
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 14, weight: .bold)
        label.textColor = Theme.secondaryAccent
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        // 組裝 Stack Views
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(memoLabel)
        
        priceInfoStack.addArrangedSubview(priceLabel)
        priceInfoStack.addArrangedSubview(durationLabel)
        
        accessoryStack.addArrangedSubview(priceInfoStack)
        accessoryStack.addArrangedSubview(photoImageView)
        
        mainStack.addArrangedSubview(timeLabel)
        mainStack.addArrangedSubview(iconView)
        mainStack.addArrangedSubview(titleStack)
        
        // 加一個彈性空間，把右側資訊推到底
        let spacer = UIView()
        mainStack.addArrangedSubview(spacer)
        mainStack.addArrangedSubview(accessoryStack)
        
        // 設定 spacer 的 hugging priority 低，讓它盡量撐開
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // 設定右側資訊抗壓縮，確保不被擠掉
        accessoryStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Main Stack 填滿 Container (留邊距)
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Time Label 固定寬度
            timeLabel.widthAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
    }
    
    func configure(with item: ItineraryItem) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = item.timestamp.map { formatter.string(from: $0) } ?? "--:--"
        titleLabel.text = item.title
        
        if let memo = item.memo, !memo.isEmpty {
            memoLabel.text = memo
            memoLabel.isHidden = false
        } else {
            memoLabel.isHidden = true
        }
        
        // 修改：價格顯示防呆
        if item.price > 0 {
            // 使用 %.0f 格式化，避免 Double 轉 Int 溢位崩潰
            // 這會顯示不帶小數點的數字，即使數字大到超過 Int 範圍也不會當機
            let priceString = String(format: "%.0f", item.price)
            priceLabel.text = "¥\(priceString)"
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
        
        // ... (保留後續 Icon, Style, Photo 邏輯)
        let imageName: String
        switch item.type {
        case "transport":
            imageName = "tram.fill"
            containerView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            iconView.tintColor = Theme.secondaryAccent
            if let dur = item.transportDuration, !dur.isEmpty {
                durationLabel.text = dur
                durationLabel.isHidden = false
            } else {
                durationLabel.isHidden = true
            }
        case "hotel":
            imageName = "bed.double.fill"
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        case "restaurant":
            imageName = "fork.knife"
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        case "activity":
            imageName = "figure.walk"
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        default:
            imageName = "mappin.circle.fill"
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        }
        iconView.image = UIImage(systemName: imageName)
        
        if let data = item.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.isHidden = false
        } else {
            photoImageView.isHidden = true
        }
    }
}

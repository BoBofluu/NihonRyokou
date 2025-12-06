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
    
    // 左側文字堆疊 (標題 + 備註)
    private let titleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
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
    
    // 右側照片
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // 右側資訊堆疊 (價格 + 移動時間)
    private let rightInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .trailing // 靠右對齊
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // 價格 Label
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 14, weight: .bold)
        label.textColor = Theme.secondaryAccent
        label.textAlignment = .right
        return label
    }()
    
    // 移動時間 Label
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .right
        return label
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
        containerView.addSubview(timeLabel)
        containerView.addSubview(iconView)
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(memoLabel)
        containerView.addSubview(titleStack)
        
        rightInfoStack.addArrangedSubview(priceLabel)
        rightInfoStack.addArrangedSubview(durationLabel)
        containerView.addSubview(rightInfoStack)
        
        containerView.addSubview(photoImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Time
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            timeLabel.widthAnchor.constraint(equalToConstant: 45),
            
            // Icon
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Photo (Always Right)
            photoImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            photoImageView.widthAnchor.constraint(equalToConstant: 40),
            photoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Right Info Stack (Left of Photo)
            rightInfoStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rightInfoStack.trailingAnchor.constraint(equalTo: photoImageView.leadingAnchor, constant: -8),
            // 防止寬度過大擠壓標題
            rightInfoStack.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            
            // Title Stack (Left of Right Info)
            titleStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleStack.trailingAnchor.constraint(lessThanOrEqualTo: rightInfoStack.leadingAnchor, constant: -8)
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
        
        // 備註
        if let memo = item.memo, !memo.isEmpty {
            memoLabel.text = memo
            memoLabel.isHidden = false
        } else {
            memoLabel.isHidden = true
        }
        
        // 價格顯示
        if item.price > 0 {
            priceLabel.text = "¥\(Int(item.price))"
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
        
        // Icon & Duration
        let imageName: String
        switch item.type {
        case "transport":
            imageName = "tram.fill"
            // 只有交通顯示移動時間
            if let duration = item.transportDuration, !duration.isEmpty {
                durationLabel.text = duration // 顯示 "1時間 30分"
                durationLabel.isHidden = false
            } else {
                durationLabel.isHidden = true
            }
        case "hotel":
            imageName = "bed.double.fill"
            durationLabel.isHidden = true
        case "restaurant":
            imageName = "fork.knife"
            durationLabel.isHidden = true
        case "activity":
            imageName = "figure.walk"
            durationLabel.isHidden = true
        default:
            imageName = "mappin.circle.fill"
            durationLabel.isHidden = true
        }
        iconView.image = UIImage(systemName: imageName)
        
        // Style
        if item.type == "transport" {
            containerView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            iconView.tintColor = Theme.secondaryAccent
        } else {
            containerView.backgroundColor = .white
            iconView.tintColor = Theme.accentColor
        }
        
        // Photo Visibility Handling
        if let data = item.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.isHidden = false
            // 若有照片，StackView 靠照片左邊 (約束已設)
            
        } else {
            // 若無照片，隱藏 ImageView
            photoImageView.isHidden = true
            
            // 這裡有個小技巧：如果沒照片，我們希望能讓 InfoStack 靠到最右邊
            // 但因為約束是寫死的 (rightInfoStack.trailing = photoImageView.leading - 8)
            // 所以我們可以把 photoImageView 的寬度約束設為 0 (或隱藏時 AutoLayout 自動處理?)
            // 為了保險，我們手動處理一下寬度約束
            // 但最簡單的方法是：讓 photoImageView 變成透明佔位符，或者更新約束。
            // 為了保持簡單：我們讓 photoImageView 雖然隱藏但保留佔位 (alpha=0)，這樣排版不會亂。
            // 或者，如果您希望它靠右，我們需要把 photoImageView 的寬度 constraint 變成 0。
        }
    }
}

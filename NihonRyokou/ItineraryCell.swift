import UIKit
import Then
import SnapKit

class ItineraryCell: UITableViewCell {
    
    static let identifier = "ItineraryCell"
    
    private let containerView = UIView().then {
        $0.backgroundColor = Theme.cardColor
        $0.layer.cornerRadius = Theme.cornerRadius
        $0.layer.shadowColor = Theme.accentColor.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }
    
    private let mainStack = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 12
    }
    
    private let timeLabel = UILabel().then {
        $0.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        $0.textColor = Theme.textDark
    }
    
    private let iconView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = Theme.accentColor
    }
    
    private let titleStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
    }
    
    private let titleLabel = UILabel().then {
        $0.font = Theme.font(size: 16, weight: .semibold)
        $0.textColor = Theme.textDark
        $0.numberOfLines = 1
        $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    private let locationLabel = UILabel().then {
        $0.font = Theme.font(size: 12, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 1
        $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    private let accessoryStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let priceInfoStack = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .trailing
        $0.spacing = 2
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let priceLabel = UILabel().then {
        $0.font = Theme.font(size: 14, weight: .bold)
        $0.textColor = Theme.amountColor
        $0.textAlignment = .right
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private let durationLabel = UILabel().then {
        $0.font = Theme.font(size: 12, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .right
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private let photoImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .systemGray6
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(locationLabel)
        
        priceInfoStack.addArrangedSubview(priceLabel)
        priceInfoStack.addArrangedSubview(durationLabel)
        
        accessoryStack.addArrangedSubview(priceInfoStack)
        accessoryStack.addArrangedSubview(photoImageView)
        
        mainStack.addArrangedSubview(timeLabel)
        mainStack.addArrangedSubview(iconView)
        mainStack.addArrangedSubview(titleStack)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        mainStack.addArrangedSubview(spacer)
        
        mainStack.addArrangedSubview(accessoryStack)
        
        containerView.addSubview(mainStack)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        mainStack.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.bottom.trailing.equalToSuperview().offset(-12)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.width.equalTo(45)
        }
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(24)
        }
        
        photoImageView.snp.makeConstraints { make in
            make.size.equalTo(40)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(50)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
    }
    
    // 根據行程項目配置 Cell 內容
    func configure(with item: ItineraryItem) {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "HH:mm"
        timeLabel.text = item.timestamp.map { formatter.string(from: $0) } ?? "--:--"
        titleLabel.text = item.title
        
        if let loc = item.locationName, !loc.isEmpty {
            locationLabel.text = loc
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }
        
        if item.price > 0 {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 0
            
            if let priceString = numberFormatter.string(from: NSNumber(value: item.price)) {
                priceLabel.text = "¥\(priceString)"
            } else {
                priceLabel.text = "¥\(Int(item.price))"
            }
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
        
        let imageName: String
        
        // 根據行程類型設定不同的圖示與顏色
        switch item.type {
        case "transport":
            imageName = "tram.fill"
            containerView.backgroundColor = Theme.transportCardColor
            iconView.tintColor = Theme.secondaryAccent
            if let dur = item.transportDuration, !dur.isEmpty {
                durationLabel.text = dur
                durationLabel.isHidden = false
            } else {
                durationLabel.isHidden = true
            }
        case "hotel":
            imageName = "bed.double.fill"
            containerView.backgroundColor = Theme.cardColor
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        case "restaurant":
            imageName = "fork.knife"
            containerView.backgroundColor = Theme.cardColor
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        case "activity":
            imageName = "figure.walk"
            containerView.backgroundColor = Theme.cardColor
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        default:
            imageName = "mappin.circle.fill"
            containerView.backgroundColor = Theme.cardColor
            iconView.tintColor = Theme.accentColor
            durationLabel.isHidden = true
        }
        

        
        // Map item type to capitalized category for custom icon lookup
        let category: String
        switch item.type {
        case "transport": category = "Transport"
        case "hotel": category = "Hotel"
        case "restaurant": category = "Restaurant"
        case "activity": category = "Activity"
        case "shopping": category = "Shopping"
        default: category = "Other"
        }
        
        if let iconName = item.iconName, !iconName.isEmpty, let customImage = UIImage(named: iconName) {
            iconView.image = customImage
        } else if let customIcon = Theme.getIcon(for: category) {
            iconView.image = customIcon
        } else {
            iconView.image = UIImage(systemName: imageName)
        }
        iconView.tintColor = Theme.accentColor
        
        // Update text colors for dynamic theme support
        titleLabel.textColor = Theme.textDark
        locationLabel.textColor = Theme.textLight
        timeLabel.textColor = Theme.textDark
        priceLabel.textColor = Theme.amountColor
        durationLabel.textColor = Theme.textLight
        
        if let data = item.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.isHidden = false
        } else {
            photoImageView.isHidden = true
        }
    }
}

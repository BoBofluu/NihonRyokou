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
        iv.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return iv
    }()
    
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
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 12, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 1
        return label
    }()
    
    private let accessoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let priceInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .trailing
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
        mainStack.addArrangedSubview(spacer)
        mainStack.addArrangedSubview(accessoryStack)
        
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        locationLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        priceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        durationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        priceInfoStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        photoImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessoryStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
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
        switch item.type {
        case "transport":
            imageName = "tram.fill"
            containerView.backgroundColor = UIColor(red: 237/255, green: 247/255, blue: 255/255, alpha: 1.0)
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

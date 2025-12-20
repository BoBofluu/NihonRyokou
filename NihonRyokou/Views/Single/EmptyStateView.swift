import UIKit
import Then
import SnapKit

class EmptyStateView: UIView {
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 16
    }
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .systemGray3
        $0.image = UIImage(systemName: "list.bullet.clipboard")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 60, weight: .light))
    }
    
    private let titleLabel = UILabel().then {
        $0.font = Theme.font(size: 18, weight: .bold)
        $0.textColor = Theme.textDark
        $0.textAlignment = .center
        $0.text = "no_items_title".localized
    }
    
    private let messageLabel = UILabel().then {
        $0.font = Theme.font(size: 14, weight: .medium)
        $0.textColor = Theme.textLight
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.text = "no_items_message".localized
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
        
        imageView.snp.makeConstraints { make in
            make.size.equalTo(80)
        }
    }
    
    func configure(title: String? = nil, message: String? = nil, imageName: String? = nil) {
        if let title = title { titleLabel.text = title }
        if let message = message { messageLabel.text = message }
        if let imageName = imageName {
            imageView.image = UIImage(systemName: imageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 60, weight: .light))
        }
    }
}

import UIKit
import SnapKit
import Then

class IconSelectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var category: String?
    var onIconSelected: ((UIImage, String) -> Void)?
    
    // Placeholder SF Symbols
    private let iconNames = [
        "airplane", "tram.fill", "bus.fill", "car.fill",
        "bed.double.fill", "house.fill", "building.2.fill", "tent.fill",
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "takeoutbag.and.cup.and.straw.fill",
        "figure.walk", "ticket.fill", "camera.fill", "bag.fill",
        "cart.fill", "creditcard.fill", "gift.fill", "tag.fill",
        "star.fill", "heart.fill", "map.fill", "flag.fill"
    ]
    
    private var currentIconNames: [String] {
        if category == "Transport" {
            return (1...38).map { "car-\($0)" }
        } else if category == "Hotel" {
            return (1...17).map { "hotel-\($0)" }
        } else if category == "Restaurant" {
            return (1...37).map { "food-\($0)" }
        } else if category == "Activity" {
            return (1...29).map { "schedule-\($0)" }
        }
        return iconNames
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(IconCell.self, forCellWithReuseIdentifier: "IconCell")
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "select_icon_title".localized
        
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - CollectionView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentIconNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IconCell", for: indexPath) as! IconCell
        let iconName = currentIconNames[indexPath.item]
        let isCustom = (category == "Transport" || category == "Hotel" || category == "Restaurant" || category == "Activity")
        cell.configure(imageName: iconName, isCustom: isCustom)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let iconName = currentIconNames[indexPath.item]
        let image: UIImage?
        
        if category == "Transport" || category == "Hotel" || category == "Restaurant" || category == "Activity" {
            image = UIImage(named: iconName)
        } else {
            image = UIImage(systemName: iconName)
        }
        
        if let image = image {
            onIconSelected?(image, iconName)
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 4 columns
        let padding: CGFloat = 20 * 2 // Left + Right inset
        let spacing: CGFloat = 16 * 3 // 3 spaces between 4 items
        let availableWidth = collectionView.bounds.width - padding - spacing
        let itemWidth = availableWidth / 4
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

class IconCell: UICollectionViewCell {
    
    private let iconView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = Theme.textDark
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = Theme.cardColor
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(30)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(imageName: String, isCustom: Bool = false) {
        if isCustom {
            iconView.image = UIImage(named: imageName)
        } else {
            iconView.image = UIImage(systemName: imageName)
        }
        iconView.tintColor = Theme.accentColor
    }
    
    override var isSelected: Bool {
        didSet {
            contentView.layer.borderWidth = isSelected ? 2 : 0
            contentView.layer.borderColor = Theme.accentColor.cgColor
        }
    }
}

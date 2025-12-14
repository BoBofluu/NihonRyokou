import UIKit
import Then
import SnapKit

class CalendarStripView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Date? is nil for "All" option (nil 代表選擇了 "全部")
    var onDateSelected: ((Date?) -> Void)?
    var onDeleteDate: ((Date) -> Void)?
    
    private var dates: [Date] = []
    private var selectedDateIndex: Int = 0 // 0 is "All" if dates is not empty (0 代表 "全部" 選項)
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(CalendarDateCell.self, forCellWithReuseIdentifier: CalendarDateCell.identifier)
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    func setDates(_ newDates: [Date]) {
        self.dates = newDates
        selectedDateIndex = 0
        collectionView.reloadData()
        
        if !dates.isEmpty {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        }
    }
    
    // 程式化選擇特定日期
    func selectDate(_ date: Date?) {
        let indexPath: IndexPath
        
        if let date = date {
            let calendar = Calendar.current
            if let index = dates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
                indexPath = IndexPath(item: index + 1, section: 0) // +1 because 0 is "All"
            } else {
                return // Date not found
            }
        } else {
            // Select "All"
            indexPath = IndexPath(item: 0, section: 0)
        }
        
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        // Manually trigger delegate logic if needed, or just update internal state
        // collectionView.selectItem doesn't trigger delegate methods automatically.
        // We usually want to reflect the UI state change.
        // If we call delegate, it might trigger circular filter logic if not careful.
        // Here we just want to update UI selection state.
        
        let oldIndex = selectedDateIndex
        selectedDateIndex = indexPath.item
        
        var indexPathsToReload = [indexPath]
        if oldIndex != selectedDateIndex {
            indexPathsToReload.append(IndexPath(item: oldIndex, section: 0))
        }
        collectionView.reloadItems(at: indexPathsToReload)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count + 1 // +1 for "All"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDateCell.identifier, for: indexPath) as! CalendarDateCell
        let isSelected = indexPath.item == selectedDateIndex
        
        if indexPath.item == 0 {
            cell.configureForAll(isSelected: isSelected)
        } else {
            let date = dates[indexPath.item - 1]
            cell.configure(with: date, isSelected: isSelected)
            
            // Add Long Press Gesture
            cell.onLongPress = { [weak self] in
                self?.onDeleteDate?(date)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let oldIndex = selectedDateIndex
        selectedDateIndex = indexPath.item
        
        var indexPathsToReload = [indexPath]
        if oldIndex != selectedDateIndex {
            indexPathsToReload.append(IndexPath(item: oldIndex, section: 0))
        }
        
        collectionView.reloadItems(at: indexPathsToReload)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        if indexPath.item == 0 {
            onDateSelected?(nil) // All
        } else {
            let date = dates[indexPath.item - 1]
            onDateSelected?(date)
        }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 70)
    }
}

class CalendarDateCell: UICollectionViewCell {
    static let identifier = "CalendarDateCell"
    
    var onLongPress: (() -> Void)?
    
    private let dayLabel = UILabel().then {
        $0.font = Theme.font(size: 12, weight: .medium)
        $0.textColor = Theme.textLight
        $0.textAlignment = .center
    }
    
    private let dateLabel = UILabel().then {
        $0.font = Theme.font(size: 18, weight: .bold)
        $0.textColor = Theme.textDark
        $0.textAlignment = .center
    }
    
    private let containerView = UIView().then {
        $0.backgroundColor = Theme.cardColor
        $0.layer.cornerRadius = 16
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.clear.cgColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPress)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            onLongPress?()
        }
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(dayLabel)
        containerView.addSubview(dateLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
    }
    
    // 配置 "全部" 選項的顯示
    func configureForAll(isSelected: Bool) {
        dayLabel.text = "ALL"
        dateLabel.text = "∞" // Infinity symbol or something to represent all
        
        updateAppearance(isSelected: isSelected)
        onLongPress = nil // Disable long press for "All"
    }
    
    // 配置特定日期的顯示
    func configure(with date: Date, isSelected: Bool) {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "E" // Mon, Tue
        dayLabel.text = formatter.string(from: date).uppercased()
        
        formatter.setLocalizedDateFormatFromTemplate("Md") // 11/6
        dateLabel.text = formatter.string(from: date)
        
        updateAppearance(isSelected: isSelected)
    }
    
    private func updateAppearance(isSelected: Bool) {
        if isSelected {
            containerView.backgroundColor = Theme.accentColor
            dayLabel.textColor = .white.withAlphaComponent(0.8)
            dateLabel.textColor = .white
            containerView.layer.shadowColor = Theme.accentColor.cgColor
            containerView.layer.shadowOpacity = 0.3
            containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            containerView.layer.shadowRadius = 6
        } else {
            containerView.backgroundColor = Theme.cardColor
            dayLabel.textColor = Theme.textLight
            dateLabel.textColor = Theme.textDark
            containerView.layer.shadowOpacity = 0
        }
    }
}

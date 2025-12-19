import UIKit
import SafariServices
import Then
import SnapKit

struct ItinerarySection {
    let date: Date
    var items: [ItineraryItem]
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + $1.price }
    }
}

class ListViewController: UIViewController {
    
    private var allItems: [ItineraryItem] = []
    private var sections: [ItinerarySection] = []
    private var selectedDate: Date? = nil // nil means "All"
    
    // MARK: - UI Components (UI 元件)
    
    // 日期選擇條，負責顯示與選擇日期
    private lazy var calendarStrip = CalendarStripView().then {
        $0.onDateSelected = { [weak self] date in
            self?.filterItems(for: date)
        }
        $0.onDeleteDate = { [weak self] date in
            self?.showBulkDeleteConfirmation(for: date)
        }
    }
    
    // 月份選擇按鈕，點擊後可快速跳轉月份
    private lazy var monthPickerButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "calendar.badge.clock"), for: .normal)
        $0.tintColor = Theme.accentColor
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.addTarget(self, action: #selector(didTapMonthPicker), for: .touchUpInside)
    }
    
    private let totalLabel = UILabel().then {
        $0.font = Theme.font(size: 16, weight: .bold)
        $0.textColor = Theme.textDark
        $0.textAlignment = .right
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.register(ItineraryCell.self, forCellReuseIdentifier: ItineraryCell.identifier)
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 80, right: 0)
        $0.sectionHeaderHeight = UITableView.automaticDimension
        $0.estimatedSectionHeaderHeight = 40
    }
    
    private let emptyStateLabel = UILabel().then {
        $0.text = "no_items_message".localized
        $0.font = Theme.font(size: 16, weight: .medium)
        $0.textColor = Theme.textLight
        $0.textAlignment = .center
        $0.isHidden = true
    }
    
    private let backgroundImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupUI()
        loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: NSNotification.Name("RefreshData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
        
        updateTheme() // Initial theme application
        
        // Remove Back Button Text for next pushed controllers
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    @objc private func updateTheme() {
        view.backgroundColor = Theme.primaryColor
        totalLabel.textColor = Theme.textDark
        monthPickerButton.tintColor = Theme.accentColor
        
        if let bgImage = Theme.backgroundImage {
            backgroundImageView.image = bgImage
            backgroundImageView.isHidden = false
            tableView.backgroundColor = .clear
        } else {
            backgroundImageView.isHidden = true
            tableView.backgroundColor = .clear
        }
        
        tableView.reloadData()
        calendarStrip.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // MARK: - Layout
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundImageView)
        view.addSubview(calendarStrip)
        view.addSubview(calendarStrip)
        view.addSubview(monthPickerButton)
        view.addSubview(totalLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        

        
        calendarStrip.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview()
            make.trailing.equalTo(monthPickerButton.snp.leading).offset(-8)
            make.height.equalTo(85)
        }
        
        monthPickerButton.snp.makeConstraints { make in
            make.centerY.equalTo(calendarStrip)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(40)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(calendarStrip.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.leading.equalToSuperview().offset(20)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private var currentMonth: Date? = nil

    // MARK: - Data (資料處理)
    
    // 從 CoreData 載入資料並更新畫面
    @objc private func loadData() {
        allItems = CoreDataManager.shared.fetchItems()
        
        let calendar = Calendar.current
        
        // Filter dates based on currentMonth if set
        let datesToDisplay: [ItineraryItem]
        if let month = currentMonth {
            datesToDisplay = allItems.filter { item in
                 guard let date = item.timestamp else { return false }
                 return calendar.isDate(date, equalTo: month, toGranularity: .month)
            }
        } else {
            datesToDisplay = allItems
        }
        
        // Extract unique dates
        let uniqueDates = Set(datesToDisplay.compactMap { item -> Date? in
            guard let date = item.timestamp else { return nil }
            return calendar.startOfDay(for: date)
        })
        let sortedDates = uniqueDates.sorted()
        
        calendarStrip.setDates(sortedDates)
        
        // If selectedDate is no longer valid, reset to nil
        if let currentSelected = selectedDate, !sortedDates.contains(currentSelected) {
            selectedDate = nil
        }
        
        // Sync CalendarStrip selection
        if let currentSelected = selectedDate {
            calendarStrip.selectDate(currentSelected)
        } else {
            filterItems(for: nil)
        }
    }
    
    // 根據選擇的日期篩選顯示項目
    private func filterItems(for date: Date?) {
        selectedDate = date
        let calendar = Calendar.current
        
        var itemsToDisplay = allItems
        
        // If "All" is selected (date is nil), but we have a currentMonth filter
        if date == nil, let month = currentMonth {
             itemsToDisplay = allItems.filter { item in
                guard let itemDate = item.timestamp else { return false }
                return calendar.isDate(itemDate, equalTo: month, toGranularity: .month)
            }
        }
        
        if let date = date {
            // Single Date: One Section
            let items = itemsToDisplay.filter { item in
                guard let itemDate = item.timestamp else { return false }
                return calendar.isDate(itemDate, inSameDayAs: date)
            }.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
            
            sections = [ItinerarySection(date: date, items: items)]
        } else {
            // All Dates (possibly filtered by month)
            let grouped = Dictionary(grouping: itemsToDisplay) { item -> Date in
                let date = item.timestamp ?? Date()
                return calendar.startOfDay(for: date)
            }
            
            let sortedDates = grouped.keys.sorted()
            sections = sortedDates.map { date in
                let items = grouped[date]!.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
                return ItinerarySection(date: date, items: items)
            }
        }
        
        updateTotalLabel()
        tableView.reloadData()
        emptyStateLabel.isHidden = sections.contains { !$0.items.isEmpty }
    }
    
    // 更新總金額標籤
    private func updateTotalLabel() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        let total = sections.reduce(0) { $0 + $1.totalAmount }
        let totalString = numberFormatter.string(from: NSNumber(value: total)) ?? "0"
        
        let totalLabelText = "total_label".localized
        
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = LanguageManager.shared.currentLocale
            formatter.dateFormat = "yyyy/MM/dd (E)"
            let dateString = formatter.string(from: date)
            totalLabel.text = "\(dateString)  \(totalLabelText): ¥\(totalString)"
        } else {
            // User requested to remove "All Items" text
            totalLabel.text = "\(totalLabelText): ¥\(totalString)"
        }
    }
    
    // MARK: - Month Picker (月份選擇器)
    
    // 顯示月份選擇選單
    @objc private func didTapMonthPicker() {
        let calendar = Calendar.current
        let uniqueMonths = Set(allItems.compactMap { item -> Date? in
            guard let date = item.timestamp else { return nil }
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components)
        })
        let sortedMonths = uniqueMonths.sorted()
        
        guard !sortedMonths.isEmpty else { return }
        
        let alert = UIAlertController(title: "select_month_title".localized, message: nil, preferredStyle: .actionSheet)
        
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "yyyy/MM"
        
        // Show All Dates Option
        alert.addAction(UIAlertAction(title: "show_all_dates".localized, style: .default) { [weak self] _ in
            self?.resetDateFilter()
        })
        
        for monthDate in sortedMonths {
            let title = formatter.string(from: monthDate)
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.filterByMonth(monthDate)
            })
        }
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = monthPickerButton
            popover.sourceRect = monthPickerButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func filterByMonth(_ monthDate: Date) {
        currentMonth = monthDate
        selectedDate = nil
        loadData()
    }
    
    private func resetDateFilter() {
        currentMonth = nil
        selectedDate = nil
        loadData()
    }
    
    // MARK: - Bulk Delete (批量刪除)
    
    // 顯示批量刪除確認視窗
    private func showBulkDeleteConfirmation(for date: Date) {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString = formatter.string(from: date)
        
        let message = "delete_all_confirm_message".localized
        
        let alert = UIAlertController(
            title: "delete_confirm_title".localized,
            message: "\(message) (\(dateString))",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "delete_action".localized, style: .destructive) { [weak self] _ in
            self?.performBulkDelete(for: date)
        })
        
        present(alert, animated: true)
    }
    
    private func performBulkDelete(for date: Date) {
        let calendar = Calendar.current
        let itemsToDelete = allItems.filter { item in
            guard let itemDate = item.timestamp else { return false }
            return calendar.isDate(itemDate, inSameDayAs: date)
        }
        
        itemsToDelete.forEach { CoreDataManager.shared.deleteItem($0) }
        loadData()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Single Delete (單項刪除)
    
    func showDeleteConfirmation(at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "delete_confirm_title".localized,
            message: "delete_confirm_message".localized,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .destructive) { [weak self] _ in
            self?.performDelete(at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func performDelete(at indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        
        CoreDataManager.shared.deleteItem(item)
        
        // Remove from global data source
        if let index = allItems.firstIndex(of: item) {
            allItems.remove(at: index)
        }
        
        // Remove from local data
        sections[indexPath.section].items.remove(at: indexPath.row)
        
        // Update TableView
        if sections[indexPath.section].items.isEmpty {
            sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none) // Update header total
        }
        
        // Update Global Total
        updateTotalLabel()
        
        // Update Calendar Strip if needed
        let calendar = Calendar.current
        let datesToDisplay: [ItineraryItem]
        if let month = currentMonth {
            datesToDisplay = allItems.filter { filterItem in
                 guard let date = filterItem.timestamp else { return false }
                 return calendar.isDate(date, equalTo: month, toGranularity: .month)
            }
        } else {
            datesToDisplay = allItems
        }
        
        let uniqueDates = Set(datesToDisplay.compactMap { filterItem -> Date? in
            guard let date = filterItem.timestamp else { return nil }
            return calendar.startOfDay(for: date)
        })
        let sortedDates = uniqueDates.sorted()
        calendarStrip.setDates(sortedDates)
        
        if let currentSelected = selectedDate, !sortedDates.contains(currentSelected) {
            selectedDate = nil
            calendarStrip.selectDate(nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                 self.filterItems(for: nil)
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Hide header if a specific date is selected
        if selectedDate != nil {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        // 增加字體大小以提高可讀性
        let label = UILabel().then {
            $0.font = Theme.font(size: 18, weight: .bold)
            $0.textColor = Theme.textDark
        }
        
        let sectionData = sections[section]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = LanguageManager.shared.currentLocale
        dateFormatter.dateFormat = "yyyy/MM/dd (E)"
        let dateStr = dateFormatter.string(from: sectionData.date)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let totalStr = numberFormatter.string(from: NSNumber(value: sectionData.totalAmount)) ?? "0"
        
        label.text = "\(dateStr)   ¥\(totalStr)"
        
        headerView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if selectedDate != nil {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItineraryCell.identifier, for: indexPath) as? ItineraryCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        let detailVC = DetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Swipe Actions (滑動動作)
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete_action".localized) { [weak self] (_, _, completion) in
            self?.showDeleteConfirmation(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = UIColor.systemRed
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        if item.type == "transport" {
            return 70
        } else {
            return 110
        }
    }
}

import UIKit
import CoreData
import SafariServices
import Then
import SnapKit

class ListViewController: UIViewController {
    
    // MARK: - Data Source
    
    var fetchedResultsController: NSFetchedResultsController<ItineraryItem>!
    
    private var currentMonth: Date? = nil
    var selectedDate: Date? = nil // Internal access for Extension
    
    // MARK: - UI Components
    
    lazy var calendarStrip = CalendarStripView().then {
        $0.onDateSelected = { [weak self] date in
            self?.filterItems(for: date)
        }
        $0.onDeleteDate = { [weak self] date in
            self?.showBulkDeleteConfirmation(for: date)
        }
    }
    
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
    
    lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.register(ItineraryCell.self, forCellReuseIdentifier: ItineraryCell.identifier)
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
        navigationItem.backButtonDisplayMode = .minimal
        
        setupUI()
        setupFetchedResultsController()
        
        // Initial Load
        updateData(reloadStrip: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NSNotification.Name("RefreshData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: NSNotification.Name("ThemeChanged"), object: nil)
        
        updateTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No need to reload all data if FRC handles updates, but we might want to refresh strip/total
        updateTotalLabel()
        updateEmptyState()
    }
    
    @objc private func refreshData() {
        // Called when external changes happen (like adding item)
        // Since FRC delegate handles updates, we might just need to allow the delegate to work
        // Howerver, if the FRC predicate needs re-evaluating or strip needs update:
        updateData(reloadStrip: true)
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
        updateTotalLabel()
    }
    
    // MARK: - Data Management (FRC)
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<ItineraryItem> = ItineraryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: CoreDataManager.shared.context,
            sectionNameKeyPath: "sectionIdentifier", // Defined in ItineraryItem+Extension.swift
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    /// Execute fetch with current filters
    private func updateData(reloadStrip: Bool = false) {
        var predicates: [NSPredicate] = []
        let calendar = Calendar.current
        
        // 1. Month Filter
        if let month = currentMonth {
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
               let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) {
                
                predicates.append(NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startOfMonth as NSDate, endOfDay as NSDate))
            }
        }
        
        // 2. Day Filter
        if let date = selectedDate {
            let startOfDay = calendar.startOfDay(for: date)
            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) {
                predicates.append(NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startOfDay as NSDate, endOfDay as NSDate))
            }
        }
        
        if predicates.isEmpty {
            fetchedResultsController.fetchRequest.predicate = nil
        } else {
            fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            updateTotalLabel()
            updateEmptyState()
        } catch {
            print("FRC Fetch Error: \(error)")
        }
        
        if reloadStrip {
            loadCalendarStripData()
        }
    }
    
    /// Lightweight fetch to populate Calendar Strip (dots)
    private func loadCalendarStripData() {
        let request: NSFetchRequest<NSFetchRequestResult> = ItineraryItem.fetchRequest()
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["timestamp"]
        request.returnsDistinctResults = true
        
        // Apply Month filter if exists, so we only show dots for that month (or all if no month)
        if let month = currentMonth {
            let calendar = Calendar.current
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
               let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) {
                 request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startOfMonth as NSDate, endOfDay as NSDate)
            }
        }
        
        do {
            if let results = try CoreDataManager.shared.context.fetch(request) as? [[String: Any]] {
                let dates = results.compactMap { $0["timestamp"] as? Date }
                let calendar = Calendar.current
                let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
                
                calendarStrip.setDates(uniqueDays)
                
                // Re-select date if valid
                if let selected = selectedDate {
                     if uniqueDays.contains(selected) {
                         calendarStrip.selectDate(selected)
                     } else {
                         // Reset selection if the date is no longer in the list (e.g. month changed or item deleted)
                         // But if we are filtering by specific date, we want to keep it? 
                         // Logic: If user picked a date, and we filter by it, it should be there.
                         // Unless we changed month.
                         if currentMonth == nil {
                             // If no month filter, user sees all dots.
                             calendarStrip.selectDate(selected) 
                         } else {
                             // If month filter, check if selected date is in valid months
                             if !uniqueDays.contains(selected) {
                                 selectedDate = nil
                                 filterItems(for: nil) // show all in month
                             }
                         }
                     }
                } else {
                    calendarStrip.selectDate(nil)
                }
            }
        } catch {
            print("Error fetching strip dates: \(error)")
        }
    }
    
    // MARK: - Actions
    
    private func filterItems(for date: Date?) {
        selectedDate = date
        updateData(reloadStrip: false) // Strip doesn't need reload when picking a date
    }
    
    private func filterByMonth(_ monthDate: Date) {
        currentMonth = monthDate
        selectedDate = nil
        updateData(reloadStrip: true)
    }
    
    private func resetDateFilter() {
        currentMonth = nil
        selectedDate = nil
        updateData(reloadStrip: true)
    }
    
    @objc private func didTapMonthPicker() {
        // Fetch all distinct months existing in DB
        let request: NSFetchRequest<NSFetchRequestResult> = ItineraryItem.fetchRequest()
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["timestamp"]
        request.returnsDistinctResults = true
        
        do {
            if let results = try CoreDataManager.shared.context.fetch(request) as? [[String: Any]] {
                let dates = results.compactMap { $0["timestamp"] as? Date }
                let calendar = Calendar.current
                let uniqueMonths = Set(dates.map { date -> Date in
                    let components = calendar.dateComponents([.year, .month], from: date)
                    return calendar.date(from: components) ?? date
                }).sorted()
                
                guard !uniqueMonths.isEmpty else { return }
                
                let alert = UIAlertController(title: "select_month_title".localized, message: nil, preferredStyle: .actionSheet)
                
                let formatter = DateFormatter()
                formatter.locale = LanguageManager.shared.currentLocale
                formatter.dateFormat = "yyyy/MM"
                
                alert.addAction(UIAlertAction(title: "show_all_dates".localized, style: .default) { [weak self] _ in
                    self?.resetDateFilter()
                })
                
                for monthDate in uniqueMonths {
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
        } catch {
            print("Error fetching months: \(error)")
        }
    }
    
    // MARK: - Delete Logic
    
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
        // Since FRC might not have all items (if filtered), we should query DB or use FRC logic
        // Safer to Query DB for ALL items on that day
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else { return }
        
        let request: NSFetchRequest<ItineraryItem> = ItineraryItem.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", start as NSDate, end as NSDate)
        
        do {
            let items = try CoreDataManager.shared.context.fetch(request)
            items.forEach { CoreDataManager.shared.deleteItem($0) }
            // FRC delegate will update UI
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Bulk delete error: \(error)")
        }
    }
    
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
        let item = fetchedResultsController.object(at: indexPath)
        CoreDataManager.shared.deleteItem(item)
    }
    
    // MARK: - UI Updates
    
    func updateTotalLabel() {
        var total: Double = 0
        if let objects = fetchedResultsController.fetchedObjects {
            total = objects.reduce(0) { $0 + $1.price }
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let totalString = numberFormatter.string(from: NSNumber(value: total)) ?? "0"
        let labelText = "total_label".localized
        
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = LanguageManager.shared.currentLocale
            formatter.dateFormat = "yyyy/MM/dd (E)"
            let dateString = formatter.string(from: date)
            totalLabel.text = "\(dateString)  \(labelText): ¥\(totalString)"
        } else {
            totalLabel.text = "\(labelText): ¥\(totalString)"
        }
    }
    
    func updateEmptyState() {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        emptyStateLabel.isHidden = count > 0
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
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
}

// MARK: - NSFetchedResultsControllerDelegate & UITableViewDataSource

extension ListViewController: NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        return sections[section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItineraryCell.identifier, for: indexPath) as? ItineraryCell else {
            return UITableViewCell()
        }
        let item = fetchedResultsController.object(at: indexPath)
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = fetchedResultsController.object(at: indexPath)
        let detailVC = DetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if selectedDate != nil { return nil }
        
        guard let sections = fetchedResultsController.sections, sections.count > section else { return nil }
        let sectionInfo = sections[section]
        let dateStr = sectionInfo.name
        
        // Calculate Section Total
        let objects = sectionInfo.objects as? [ItineraryItem] ?? []
        let sectionTotal = objects.reduce(0) { $0 + $1.price }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel().then {
            $0.font = Theme.font(size: 18, weight: .bold)
            $0.textColor = Theme.textDark
        }
        
        // Parse "yyyy-MM-dd" back to display format
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        // Ensure same locale as when created
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = LanguageManager.shared.currentLocale
        displayFormatter.dateFormat = "yyyy/MM/dd (E)"
        
        let displayDateStr: String
        if let date = inputFormatter.date(from: dateStr) {
            displayDateStr = displayFormatter.string(from: date)
        } else {
            displayDateStr = dateStr
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let totalStr = numberFormatter.string(from: NSNumber(value: sectionTotal)) ?? "0"
        
        label.text = "\(displayDateStr)   ¥\(totalStr)"
        
        headerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if selectedDate != nil { return 0 }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = fetchedResultsController.object(at: indexPath)
        if item.type == "transport" {
            return 70
        } else {
            return 110
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete_action".localized) { [weak self] (_, _, completion) in
            self?.showDeleteConfirmation(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = UIColor.systemRed
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // MARK: - FRC Delegate (Automatic Updates)
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                 // Reconfigure cell
                if let cell = tableView.cellForRow(at: indexPath) as? ItineraryCell,
                   let item = anObject as? ItineraryItem {
                    cell.configure(with: item)
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateTotalLabel()
        updateEmptyState()
        loadCalendarStripData() // Refresh dots on data change
    }
}

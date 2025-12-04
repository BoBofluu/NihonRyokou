import UIKit
import SafariServices

// Struct 保持不變
struct ItinerarySection {
    let date: Date
    let totalAmount: Double
    var items: [ItineraryItem]
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Theme.primaryColor
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private var sections: [ItinerarySection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.primaryColor
        title = "app_title".localized
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        title = "app_title".localized // 確保語言切換後標題更新
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItineraryCell.self, forCellReuseIdentifier: ItineraryCell.identifier)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func fetchData() {
        let allItems = CoreDataManager.shared.fetchItems()
        
        let grouped = Dictionary(grouping: allItems) { item -> Date in
            let date = item.timestamp ?? Date()
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return Calendar.current.date(from: components) ?? date
        }
        
        let sortedDates = grouped.keys.sorted()
        
        self.sections = sortedDates.map { date in
            let itemsInDate = grouped[date] ?? []
            let sortedItems = itemsInDate.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
            let total = sortedItems.reduce(0) { $0 + $1.price }
            return ItinerarySection(date: date, totalAmount: total, items: sortedItems)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // Header 設定：包含日期與多語言 Total
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.font(size: 18, weight: .bold)
        label.textColor = Theme.textDark
        
        let sectionData = sections[section]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        
        let dateStr = dateFormatter.string(from: sectionData.date)
        let priceStr = "¥\(Int(sectionData.totalAmount))"
        let totalLabel = "total".localized // 使用多語言 Key
        
        label.text = "\(dateStr)    \(totalLabel): \(priceStr)"
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItineraryCell.identifier, for: indexPath) as? ItineraryCell else {
            return UITableViewCell()
        }
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        
        // 處理刪除按鈕點擊事件
        cell.onDelete = { [weak self] in
            guard let self = self else { return }
            self.showDeleteConfirmation(at: indexPath)
        }
        
        return cell
    }
    
    private func showDeleteConfirmation(at indexPath: IndexPath) {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        
        if let urlString = item.locationURL, !urlString.isEmpty, let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = Theme.accentColor
            present(safariVC, animated: true)
        }
    }
    
    // MARK: - 刪除功能 (Swipe Action with Alert)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete_action".localized) { [weak self] (_, _, completion) in
            self?.showDeleteConfirmation(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func performDelete(at indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        CoreDataManager.shared.deleteItem(item)
        sections[indexPath.section].items.remove(at: indexPath.row)
        
        if sections[indexPath.section].items.isEmpty {
            sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // 重新計算總額
            let newItems = sections[indexPath.section].items
            let newTotal = newItems.reduce(0) { $0 + $1.price }
            let oldDate = sections[indexPath.section].date
            sections[indexPath.section] = ItinerarySection(date: oldDate, totalAmount: newTotal, items: newItems)
            
            // 延遲刷新 Header
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

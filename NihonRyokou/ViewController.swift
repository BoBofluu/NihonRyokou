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
        
        navigationItem.title = "app_title".localized
        
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        
        navigationItem.title = "app_title".localized
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
    
    // Header 設定：修改日期格式以顯示星期
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.font(size: 18, weight: .bold)
        label.textColor = Theme.textDark
        
        let sectionData = sections[section]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy/MM/dd (EEE)"
        
        let dateStr = dateFormatter.string(from: sectionData.date)
        
        // 修改：使用 String(format:) 避免 Int 溢位崩潰
        // 原本: let priceStr = "¥\(Int(sectionData.totalAmount))" -> 會崩潰
        let priceStr = String(format: "%.0f", sectionData.totalAmount)
        
        let totalLabel = "total".localized
        
        label.text = "\(dateStr)    \(totalLabel): ¥\(priceStr)"
        
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
        
        if indexPath.section < sections.count && indexPath.row < sections[indexPath.section].items.count {
            let item = sections[indexPath.section].items[indexPath.row]
            cell.configure(with: item)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        let detailVC = DetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - 刪除功能
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete_action".localized) { [weak self] (_, _, completion) in
            self?.showDeleteConfirmation(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
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
    
    private func performDelete(at indexPath: IndexPath) {
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].items.count else { return }
        
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if indexPath.section < self.sections.count {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        
        if item.type == "transport" {
            return 55
        } else {
            return 110
        }
    }
}

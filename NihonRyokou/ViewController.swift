import UIKit
import SafariServices

// 用來管理分組資料的結構
struct ItinerarySection {
    let date: Date
    let totalAmount: Double
    var items: [ItineraryItem]
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView: UITableView = {
        // 使用 insetGrouped 風格，讓區塊更明顯（Q版風格）
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Theme.primaryColor
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // 改用 Section 陣列來儲存分組後的資料
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
        fetchData() // 每次出現頁面重新抓取資料
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
        
        // 1. 依照日期分組 (忽略時間，只看年月日)
        let grouped = Dictionary(grouping: allItems) { item -> Date in
            let date = item.timestamp ?? Date()
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return Calendar.current.date(from: components) ?? date
        }
        
        // 2. 轉換成 Section 結構並排序 (日期早的在上面)
        let sortedDates = grouped.keys.sorted()
        
        self.sections = sortedDates.map { date in
            let itemsInDate = grouped[date] ?? []
            // 同一天內的行程依照時間排序
            let sortedItems = itemsInDate.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
            // 計算該日總額
            let total = sortedItems.reduce(0) { $0 + $1.price }
            
            return ItinerarySection(date: date, totalAmount: total, items: sortedItems)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // 自定義 Header (顯示日期與總額)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        // headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.font(size: 18, weight: .bold)
        label.textColor = Theme.textDark
        
        let sectionData = sections[section]
        
        // 日期格式化
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current // 跟隨系統或語言設定
        
        let dateStr = dateFormatter.string(from: sectionData.date)
        let priceStr = "¥\(Int(sectionData.totalAmount))"
        
        // 組合顯示文字
        label.text = "\(dateStr)    Total: \(priceStr)"
        
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
        return cell
    }
    
    // 點擊事件：只有在有 URL 時才開啟
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        
        if let urlString = item.locationURL, !urlString.isEmpty, let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = Theme.accentColor
            present(safariVC, animated: true)
        }
        // 若無 URL，因為 Cell 設定了 selectionStyle = .none (在 ItineraryCell 中設定)，視覺上不會有點擊反應
    }
    
    // 刪除功能：使用 trailingSwipeActionsConfiguration 實作彈跳視窗確認
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "delete_action".localized) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // 顯示確認視窗 (Alert)
            let alert = UIAlertController(
                title: "delete_confirm_title".localized,
                message: "delete_confirm_message".localized,
                preferredStyle: .alert
            )
            
            // 取消按鈕
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel) { _ in
                completionHandler(false) // 告訴系統刪除取消了，滑動會收回去
            })
            
            // 確認刪除按鈕
            alert.addAction(UIAlertAction(title: "confirm".localized, style: .destructive) { _ in
                self.performDelete(at: indexPath)
                completionHandler(true) // 告訴系統刪除完成了
            })
            
            self.present(alert, animated: true)
        }
        
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // 執行實際的刪除邏輯
    private func performDelete(at indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        
        // 1. 從 Core Data 資料庫刪除
        CoreDataManager.shared.deleteItem(item)
        
        // 2. 更新本地資料來源 (Sections)
        sections[indexPath.section].items.remove(at: indexPath.row)
        
        // 3. 更新 UI
        if sections[indexPath.section].items.isEmpty {
            // 如果該天沒行程了，刪除整個 Section
            sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            // 否則只刪除該行
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // 重新計算該 Section 總額
            let newItems = sections[indexPath.section].items
            let newTotal = newItems.reduce(0) { $0 + $1.price }
            
            // 更新 Struct 資料
            let oldDate = sections[indexPath.section].date
            sections[indexPath.section] = ItinerarySection(date: oldDate, totalAmount: newTotal, items: newItems)
            
            // 為了更新 Header 上的總金額，我們需要刷新該 Section (或者只刷新 Header，但 reloadSection 比較簡單)
            // 延遲一點點執行以免動畫衝突，或者使用 UIView.performWithoutAnimation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110 // 稍微增加高度以容納資訊
    }
}

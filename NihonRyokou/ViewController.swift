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
        // 使用 .insetGrouped 樣式讓 Section 之間有區隔，符合 Q 版風格
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Theme.primaryColor
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // 改用 Section 陣列
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
        fetchData() // 每次出現時重新整理資料
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
        
        // 1. 依照日期分組
        let grouped = Dictionary(grouping: allItems) { item -> Date in
            // 只取年月日，忽略時間
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
            // 計算當日總額
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
        // headerView.backgroundColor = .clear // 透明背景
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.font(size: 18, weight: .bold)
        label.textColor = Theme.textDark
        
        let sectionData = sections[section]
        
        // 日期格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        // 若有多語言需求，可設 locale，這裡跟隨系統
        dateFormatter.locale = Locale.current
        
        let dateStr = dateFormatter.string(from: sectionData.date)
        let priceStr = "¥\(Int(sectionData.totalAmount))"
        
        // 組合字串： "2025年11月30日   Total: ¥8000"
        label.text = "\(dateStr)    Total: \(priceStr)"
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        
        // 判斷是否有 URL，若無則直接返回（無點擊效果）
        guard let urlString = item.locationURL, !urlString.isEmpty, let url = URL(string: urlString) else {
            // 可選擇加上震動提示這是不可點的，或是直接不反應
            return
        }
        
        // 點擊動畫
        tableView.deselectRow(at: indexPath, animated: true)
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = Theme.accentColor
        present(safariVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = sections[indexPath.section].items[indexPath.row]
            
            // 從 Core Data 刪除
            CoreDataManager.shared.deleteItem(item)
            
            // 更新本地資料源
            sections[indexPath.section].items.remove(at: indexPath.row)
            // 若該 Section 空了，連 Section 一起刪除；否則只刪 Row
            if sections[indexPath.section].items.isEmpty {
                sections.remove(at: indexPath.section)
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
            } else {
                // 重新計算該 Section 總額 (因為少了一個項目)
                let newItems = sections[indexPath.section].items
                let newTotal = newItems.reduce(0) { $0 + $1.price }
                // 由於 struct 是 value type，需重新賦值更新
                let oldDate = sections[indexPath.section].date
                sections[indexPath.section] = ItinerarySection(date: oldDate, totalAmount: newTotal, items: newItems)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                // 重新整理 Header 以更新總額
                UIView.performWithoutAnimation {
                    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110 // 稍微加高一點以容納右下角的連結提示
    }
}

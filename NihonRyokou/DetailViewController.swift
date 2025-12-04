//
//  DetailViewController.swift
//  NihonRyokou
//
//  Created by m.li on 2025/12/04.
//

import UIKit
import WebKit

class DetailViewController: UIViewController {
    
    private let item: ItineraryItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 24, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .medium)
        label.textColor = Theme.textLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 20, weight: .bold)
        label.textColor = Theme.secondaryAccent
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.font(size: 16, weight: .regular)
        label.numberOfLines = 0
        label.textColor = Theme.textDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 用來顯示 Google Map
    private lazy var webView: WKWebView = {
        let web = WKWebView()
        web.translatesAutoresizingMaskIntoConstraints = false
        web.layer.cornerRadius = 12
        web.clipsToBounds = true
        web.backgroundColor = .systemGray6
        return web
    }()
    
    init(item: ItineraryItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Details"
        
        setupUI()
        configureData()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(memoLabel)
        contentView.addSubview(webView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Photo: 寬度填滿，高度固定 (例如 300)
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            priceLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            memoLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            memoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            memoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Map WebView
            webView.topAnchor.constraint(equalTo: memoLabel.bottomAnchor, constant: 20),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            webView.heightAnchor.constraint(equalToConstant: 250),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func configureData() {
        titleLabel.text = item.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        if let date = item.timestamp {
            timeLabel.text = formatter.string(from: date)
        }
        
        priceLabel.text = "¥\(Int(item.price))"
        memoLabel.text = item.memo ?? "No memo"
        
        // 圖片
        if let data = item.photoData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
            // 若沒圖片，把 Title 往上推
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        }
        
        // Google Map Logic
        if let urlStr = item.locationURL, let url = URL(string: urlStr) {
            if urlStr.lowercased().contains("google.com/maps") || urlStr.lowercased().contains("goo.gl") {
                // 如果是 Google Map 連結，載入 WebView
                webView.isHidden = false
                let request = URLRequest(url: url)
                webView.load(request)
            } else {
                // 如果是一般連結，隱藏地圖 (或者您可以選擇做一個按鈕開啟 Safari)
                webView.isHidden = true
            }
        } else {
            webView.isHidden = true
        }
    }
}

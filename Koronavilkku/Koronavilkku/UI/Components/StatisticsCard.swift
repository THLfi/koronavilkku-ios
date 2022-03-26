import UIKit

final class StatisticsCard: CardElement {
    init(title: String, body: String) {
        super.init()
        
        let titleView = UILabel(label: title, font: .heading2, color: .Primary.blue)
        titleView.numberOfLines = 0
        
        let bodyView = UILabel(label: body, font: .bodySmall, color: .Greyscale.black)
        bodyView.numberOfLines = 0
        
        if #available(iOS 14.0, *) {
            titleView.lineBreakStrategy = .hangulWordPriority
            bodyView.lineBreakStrategy = .hangulWordPriority
        }

        addSubview(titleView)
        addSubview(bodyView)

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(20)
        }
        
        bodyView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.bottom.left.right.equalToSuperview().inset(20)
        }
        
        isAccessibilityElement = true
        accessibilityLabel = "\(title) \(body)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

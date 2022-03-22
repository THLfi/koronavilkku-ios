import UIKit

final class StatisticsCard: WideRowElement {
    
    init(title: String, body: String) {
        super.init()
        
        let margin = UIEdgeInsets(top: 20, left: 20, bottom: -20, right: -20)
        
        let container = UIView()
        let textContainer = UIView()
        
        let rightPadding = UIView()
        let titleView = createTitleLabel(title: title)
        titleView.font = .heading2
        titleView.textColor = UIColor.Primary.blue
        
        let bodyView = createBodyLabel(body: body)
        bodyView.font = .bodyLarge
        
        self.addSubview(container)
        container.addSubview(textContainer)
        container.addSubview(rightPadding)
        textContainer.addSubview(titleView)
        textContainer.addSubview(bodyView)
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        textContainer.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(margin.top)
            make.bottom.lessThanOrEqualToSuperview().offset(margin.bottom)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(margin.left)
            
            make.right.equalTo(rightPadding.snp.left).offset(36)
        }

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        bodyView.snp.makeConstraints{ make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.bottom.left.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
        }
        
        rightPadding.snp.makeConstraints { make in
          make.bottom.right.equalToSuperview()
          make.top.greaterThanOrEqualToSuperview()
          make.size.equalTo(CGSize(width: 30, height: 110))
        }
        
        
        container.clipsToBounds = true
        container.layer.cornerRadius = cornerRadius
        titleView.isAccessibilityElement = false
        bodyView.isAccessibilityElement = false
        
        rightPadding.accessibilityTraits = .none
        
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = titleView.text
        self.accessibilityValue = bodyView.text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

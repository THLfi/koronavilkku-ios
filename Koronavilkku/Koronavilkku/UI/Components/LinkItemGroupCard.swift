import Foundation
import UIKit
import SnapKit

class LinkItemGroupCard: CardElement {
    
    init(items: [LinkItem]) {
        super.init()
        
        let container = self
        var topConstraint = container.snp.top
        var index = 0

        items.forEach { item in
            container.addSubview(item)
            let isLast = index == items.count - 1
            
            item.snp.makeConstraints { make in
                make.trailing.leading.equalToSuperview()
                make.top.equalTo(topConstraint)
                
                if isLast {
                    make.bottom.equalToSuperview()
                }
            }

            topConstraint = item.snp.bottom

            if !isLast {
                let separator = LinkItemGroupCard.createSeparator()
                container.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(20)
                    make.right.equalToSuperview().offset(-20)
                    make.height.equalTo(1)
                    make.top.equalTo(topConstraint)
                }
            }
            
            index += 1
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor.Greyscale.borderGrey
        return separator
    }
}

import Foundation
import UIKit
import SnapKit

class LinkItemCard: CardElement {
    
    let linkItem: LinkItem
    
    init(title: String, linkName: String? = nil, value: String? = nil, tapped: @escaping TapHandler) {
        self.linkItem = LinkItem(title: title, linkName: linkName, value: value, tapped: tapped)
        
        super.init()

        addSubview(linkItem)
        linkItem.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

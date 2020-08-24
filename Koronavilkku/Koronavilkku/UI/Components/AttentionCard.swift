import Foundation
import UIKit
import SnapKit

class AttentionCard: CardElement {
    
    init(text: String) {
        super.init()

        let label = AttentionLabel(text: text)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

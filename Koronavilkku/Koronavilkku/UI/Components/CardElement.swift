import Foundation
import UIKit
import SnapKit

class CardElement: UIView {
    
    let cornerRadius = CGFloat(14)

    init() {
        super.init(frame: .zero)
        configureLayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayer() {
        self.backgroundColor = UIColor.Greyscale.white
        setElevation(.elevation1)
        self.layer.cornerRadius = cornerRadius
    }
}

extension UIView {
    func embedInCard() -> CardElement {
        let card = CardElement()
        card.addSubview(self)
        
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return card
    }
}

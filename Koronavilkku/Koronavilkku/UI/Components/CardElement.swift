import Foundation
import UIKit
import SnapKit

class CardElement: UIView {
    
    let cornerRadius = CGFloat(14)

    init() {
        super.init(frame: .zero)
        configureLayer()
    }
    
    convenience init(embed view: UIView) {
        self.init()
        self.addSubview(view)
        
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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

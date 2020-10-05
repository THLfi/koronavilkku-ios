import Foundation
import UIKit
import SnapKit

class CardElement: UIView {

    init() {
        super.init(frame: .zero)
        configureLayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 14).cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayer() {
        self.backgroundColor = UIColor.Greyscale.white
        self.layer.shadowColor = .dropShadow
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 14
        self.layer.cornerRadius = 14
    }
}

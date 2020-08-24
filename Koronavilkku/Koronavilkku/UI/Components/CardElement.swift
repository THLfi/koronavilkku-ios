import Foundation
import UIKit
import SnapKit

class CardElement: UIView {

    init() {
        super.init(frame: .zero)
        configureLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayer() {
        self.backgroundColor = UIColor.Greyscale.white
        self.layer.shadowColor = UIColor.Primary.blue.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 7
        self.layer.cornerRadius = 14
    }
}

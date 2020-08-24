import Foundation
import UIKit
import SnapKit

class AttentionLabel: UIView {
    
    init(text: String) {
        super.init(frame: .zero)

        let image = UIImageView(image: UIImage(named: "alert-octagon")!.withTintColor(UIColor.Primary.red))
        image.contentMode = .scaleAspectFit
        addSubview(image)
        image.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }
        
        let label = UILabel(label: text,
                       font: UIFont.labelSecondary,
                       color: UIColor.Primary.red)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(14)
            make.top.equalTo(image)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

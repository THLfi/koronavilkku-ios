import SnapKit
import UIKit

class FooterItem : UIButton {
    private let tapHandler: TapHandler
    
    init(title: String, action: @escaping TapHandler) {
        tapHandler = action
        super.init(frame: .zero)
        
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        let label = UILabel(label: title, font: .labelTertiary, color: UIColor.Greyscale.darkGrey)
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }
        
        let icon = UIImageView(image: UIImage(named: "chevron-right"))
        addSubview(icon)
        
        icon.snp.makeConstraints { make in
            make.centerY.right.equalToSuperview()
            make.left.greaterThanOrEqualTo(label.snp.right).offset(10)
        }
        
        accessibilityLabel = title
        accessibilityTraits = .link
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapped() {
        tapHandler()
    }
}

extension Collection where Element == FooterItem {
    func build() -> UIView {
        UIView().layout { append in
            append(UIView.createDivider(), nil)
            
            for item in self {
                append(item, UIEdgeInsets(top: 12, bottom: 12))
                append(UIView.createDivider(), nil)
            }
        }
    }
}

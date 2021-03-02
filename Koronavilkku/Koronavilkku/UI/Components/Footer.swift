import SnapKit
import UIKit

class FooterItem : UIButton {
    private let tapHandler: TapHandler
    
    init(title: String, padding: UIEdgeInsets = .init(), action: @escaping TapHandler) {
        tapHandler = action
        super.init(frame: .zero)
        
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        let label = UILabel(label: title, font: .labelTertiary, color: UIColor.Greyscale.darkGrey)
        label.numberOfLines = 0
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview().inset(padding)
        }
        
        let icon = UIImageView(image: UIImage(named: "chevron-right"))
        icon.contentMode = .center
        addSubview(icon)
        
        icon.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(padding)
            make.centerY.equalTo(label)
            make.left.greaterThanOrEqualTo(label.snp.right).offset(16)
            make.size.equalTo(CGSize(width: 24, height: 24))
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
                append(item, UIEdgeInsets(top: 10, bottom: 12))
                append(UIView.createDivider(), nil)
            }
        }
    }
}

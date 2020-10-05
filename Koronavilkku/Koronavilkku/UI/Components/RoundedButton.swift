import Foundation
import UIKit

class RoundedButton: UIButton {

    override var buttonType: UIButton.ButtonType {
        .system
    }
    
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : enabledBackgroundColor
            layer.shadowColor = isHighlighted ? UIColor.clear.cgColor : UIColor.Greyscale.lightGrey.cgColor
        }
    }
    
    static let height: CGFloat = 50
    
    let title: String
    let action: () -> ()
    private let enabledBackgroundColor: UIColor
    private let highlightedBackgroundColor: UIColor
    
    init(title: String,
         disabledTitle: String? = nil,
         backgroundColor: UIColor = UIColor.Primary.blue,
         highlightedBackgroundColor: UIColor = UIColor.Secondary.buttonHighlightedBackground,
         action: @escaping () -> ()) {
        
        self.title = title
        self.action = action
        self.enabledBackgroundColor = backgroundColor
        self.highlightedBackgroundColor = highlightedBackgroundColor
        
        super.init(frame: .zero)
            
        self.setTitle(title, for: .normal)
        self.setTitleColor(UIColor.Greyscale.white, for: .normal)
        self.backgroundColor = backgroundColor
        self.titleLabel?.font = UIFont.labelPrimary
        
        self.layer.cornerRadius = 25
        self.layer.shadowColor = .dropShadow
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 14
        self.addTarget(self, action: #selector(performAction), for: .touchUpInside)
        
        self.snp.makeConstraints { make in
            make.height.equalTo(RoundedButton.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 25).cgPath
    }
    
    @objc func performAction() {
        action()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
        backgroundColor = enabled ? enabledBackgroundColor : UIColor.Greyscale.lightGrey
    }
}

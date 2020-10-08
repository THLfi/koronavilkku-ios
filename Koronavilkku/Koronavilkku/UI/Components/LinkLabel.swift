import Foundation
import UIKit

class LinkLabel: UILabel {
    
    let tapped: TapHandler
    var contentInset: UIEdgeInsets = .zero
    
    init(label: String, font: UIFont, color: UIColor, underline: Bool = true, tapped: @escaping TapHandler) {
        self.tapped = tapped
        super.init(frame: .zero)
        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ]
        
        if underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        let attributed = NSAttributedString(string: label,
                                            attributes: attributes)
        self.attributedText = attributed
        self.isUserInteractionEnabled = true
        
        self.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(handleTap)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleTap() {
        tapped()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitArea = self.bounds.inset(by: contentInset)
        return hitArea.contains(point) ? self : nil
    }
}

class InternalLinkLabel: UILabel {
    
    private let linkTapped:  () -> ()
    
    init(label: String, font: UIFont, color: UIColor, linkTapped: @escaping () -> (), underline: Bool = true) {
        
        self.linkTapped = linkTapped
        super.init(frame: .zero)
        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ]
        
        if underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        let attributed = NSAttributedString(string: label,
                                            attributes: attributes)
        self.attributedText = attributed
        self.isUserInteractionEnabled = true
        
        self.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tapped)))
    }
    
    @objc func tapped() {
        self.linkTapped()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

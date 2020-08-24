import UIKit

extension UILabel {

    convenience init(label: String, font: UIFont, color: UIColor) {
        self.init()
        self.text = label
        self.font = font
        self.textColor = color
    }
    
    func setLineHeight(_ lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeight
        attributedText = NSMutableAttributedString(string: text ?? "", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }
}

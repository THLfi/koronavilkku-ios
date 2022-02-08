import UIKit

class BulletItem: UILabel {
    static let indentation = CGFloat(30)
    static let bulletBounds = CGRect(x: 0, y: 0.5, width: 8, height: 8)
    
    private var _text: String?
    
    override var text: String? {
        get {
            _text
        }
        
        set {
            _text = newValue
            render()
        }
    }
    
    override var textColor: UIColor! {
        didSet {
            render()
        }
    }
    
    init(text: String, textColor: UIColor = UIColor.Greyscale.black) {
        super.init(frame: .zero)
        self.numberOfLines = 0
        self._text = text
        self.textColor = textColor
        render()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render() {
        guard let text = _text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: Self.indentation)]
        paragraphStyle.headIndent = Self.indentation
        
        let finalString = NSMutableAttributedString(string: " ", attributes: [
            .paragraphStyle: paragraphStyle,
        ])

        let attachment = NSTextAttachment(image: UIImage(named: "bullet")!.withTintColor(UIColor.Primary.blue))
        let attachmentString = NSAttributedString(attachment: attachment)
        finalString.append(attachmentString)

        let textString = NSAttributedString(string: "\t\(text)", attributes: [
            .font: UIFont.bodySmall,
            .foregroundColor: textColor ?? UIColor.Greyscale.black,
        ])
        finalString.append(textString)

        self.attributedText = finalString
    }
}

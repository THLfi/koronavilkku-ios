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
        
        let attachment = NSTextAttachment(image: UIImage(named: "bullet")!.withTintColor(UIColor.Primary.blue))
        attachment.bounds = Self.bulletBounds
        let attachmentString = NSAttributedString(attachment: attachment)

        let spacerString = NSAttributedString(string: "\u{200B}", attributes: [
            NSAttributedString.Key.kern: Self.indentation - Self.bulletBounds.width
        ])

        let textString = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key.font: UIFont.bodySmall,
            NSAttributedString.Key.foregroundColor: textColor ?? UIColor.Greyscale.black
        ])
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = Self.indentation
        
        let attributedString = NSMutableAttributedString(string: "\u{200B}", attributes: [
            NSAttributedString.Key.paragraphStyle : paragraphStyle,
        ])

        attributedString.append(attachmentString)
        attributedString.append(spacerString)
        attributedString.append(textString)

        self.attributedText = attributedString
    }
}

import UIKit

class BulletItem: UILabel {
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
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 30
        
        let attributedString = NSMutableAttributedString(string: "\u{200B}", attributes: [
            NSAttributedString.Key.paragraphStyle : paragraphStyle,
        ])

        let attachment = NSTextAttachment(image: UIImage(named: "bullet")!.withTintColor(UIColor.Primary.blue))
        let attachmentString = NSAttributedString(attachment: attachment)
        attributedString.append(attachmentString)

        let spacing = NSAttributedString(string: "\u{200B}", attributes: [
            NSAttributedString.Key.kern: 22
        ])
        attributedString.append(spacing)

        let textString = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key.font: UIFont.bodySmall,
            NSAttributedString.Key.foregroundColor: textColor ?? UIColor.Greyscale.black
        ])
        attributedString.append(textString)
        
        numberOfLines = 0
        attributedText = attributedString
    }
}

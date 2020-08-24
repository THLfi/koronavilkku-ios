import Foundation
import UIKit

protocol Paragraph {
    var content: String { get }
    func get() -> NSAttributedString
}

struct HeaderParagraphWithImage: Paragraph {
    
    let image: String
    let content: String
    
    let paragraphSpacing: CGFloat = 10
    let paragraphStyle = NSMutableParagraphStyle()
    let indentation: CGFloat = 40
    
    func get() -> NSAttributedString {
        
        let fullString = NSMutableAttributedString()
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: image)!.withTintColor(UIColor.Primary.blue)
        let imageString = NSAttributedString(attachment: attachment)

        fullString.append(imageString)
        
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation)
        ]
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        
        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.heading4,
            NSAttributedString.Key.foregroundColor: UIColor.Greyscale.black
        ]
        
        let attributedString = NSMutableAttributedString(
            string: "\t\(content)", attributes: textAttributes
        )
        
        fullString.append(attributedString)
        return fullString
    }
}

struct WarningParagraphWithImage: Paragraph {
    
    let image: String
    let content: String
    
    let paragraphSpacing: CGFloat = 10
    let paragraphStyle = NSMutableParagraphStyle()
    let indentation: CGFloat = 40
    
    func get() -> NSAttributedString {
        
        let fullString = NSMutableAttributedString()
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: image)!.withTintColor(UIColor.Primary.red)
        let imageString = NSAttributedString(attachment: attachment)

        fullString.append(imageString)
        
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation)
        ]
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        paragraphStyle.firstLineHeadIndent = indentation
        
        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.labelSecondary,
            NSAttributedString.Key.foregroundColor: UIColor.Primary.red,
        ]
        
        let attributedString = NSMutableAttributedString(
            string: "\t\t\(content)", attributes: textAttributes
        )
    
        attributedString.addAttribute(NSAttributedString.Key.baselineOffset,
                                      value: UIFont.labelSecondary.fontDescriptor.pointSize / 2,
                                      range: NSRange(location: 0, length: content.count+2))
        
        fullString.append(attributedString)
        return fullString
    }
}


struct TextParagraph: Paragraph {
    let content: String
    func get() -> NSAttributedString {
        return NSAttributedString(string: content)
    }
}

private let defaultLineSpacing: CGFloat = 1.17
private let defaultParagraphSpacing: CGFloat = 10
private let defaultIndentation: CGFloat = 20

struct IndentedParagraph: Paragraph {
    
    let content: String
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let indentation: CGFloat
    let textColor: UIColor
    
    init(content: String, lineSpacing: CGFloat = defaultLineSpacing, paragraphSpacing: CGFloat = defaultParagraphSpacing, indentation: CGFloat = defaultIndentation, textColor: UIColor = UIColor.Greyscale.black) {
        self.content = content
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.indentation = indentation
        self.textColor = textColor
    }

    func get() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation)
        ]
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation

        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.bodySmall,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        
        return NSMutableAttributedString(string: "\t\(content)", attributes: textAttributes)
    }
}

struct BulletListParagraph: Paragraph {
    
    let content: String
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let indentation: CGFloat
    let textColor: UIColor
    
    init(content: String, lineSpacing: CGFloat = defaultLineSpacing, paragraphSpacing: CGFloat = defaultParagraphSpacing, indentation: CGFloat = defaultIndentation, textColor: UIColor = UIColor.Greyscale.black) {
        self.content = content
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.indentation = indentation
        self.textColor = textColor
    }

    func get() -> NSAttributedString {
        
        let bulletCharacter: String = "\u{2022}"
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation)
        ]
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation

        let bullet = NSMutableAttributedString()
        
        let bulletItem = "\(bulletCharacter)\t\(content)"
        
        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.bodySmall,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        
        let attributedString = NSMutableAttributedString(
            string: bulletItem, attributes: textAttributes
        )
        
        let bulletAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.bodyLarge,
            NSAttributedString.Key.foregroundColor: UIColor.Primary.blue
        ]
        
        let bulletRange = (bulletItem as NSString).range(of: bulletCharacter)
        attributedString.addAttributes(bulletAttributes, range: bulletRange)
        
        bullet.append(attributedString)
        

        return bullet
    }
}

extension NSAttributedString {
    
    func toLabel() -> UILabel {
        let label = UILabel()
        label.attributedText = self
        label.numberOfLines = 0
        return label
    }
}

extension Array where Element == BulletListParagraph {
    
    func asMutableAttributedString() -> NSMutableAttributedString {
        var i = 0

        return reduce(into: NSMutableAttributedString()) { (result, paragraph) in
            result.append(paragraph.get())

            // Don't add an empty line to the end.
            if i < count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }

            i += 1
        }
    }
}

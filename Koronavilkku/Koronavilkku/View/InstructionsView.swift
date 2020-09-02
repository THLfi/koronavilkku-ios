import SnapKit
import UIKit

struct InstructionItem {
    let view: UIView
    let makeConstraints: (_ topConstraint: ConstraintItem, _ make: ConstraintMaker) -> Void
    
    init(view: UIView, spacing: CGFloat = 0, makeConstraints: ((_ topConstraint: ConstraintItem, _ make: ConstraintMaker) -> Void)? = nil) {
        self.view = view
        
        self.makeConstraints = makeConstraints ?? { topConstraint, make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topConstraint).offset(spacing)
        }
    }
}

struct InstructionsView {

    static func layoutItems(_ items: [InstructionItem], contentView: UIView) -> ConstraintItem {
        contentView.removeAllSubviews()
        
        var topConstraint = contentView.snp.top

        items.forEach { item in
            contentView.addSubview(item.view)

            item.view.snp.makeConstraints { make in
                item.makeConstraints(topConstraint, make)
            }

            topConstraint = item.view.snp.bottom
        }
        
        return topConstraint
    }

    static func bulletList(items: [BulletListParagraph], spacing: CGFloat) -> InstructionItem {
        return InstructionItem(view: items.asMutableAttributedString().toLabel(), spacing: spacing)
    }

    static func labelItem(_ text: Translation, font: UIFont, color: UIColor, spacing: CGFloat) -> InstructionItem {
        return labelItem(text.localized, font: font, color: color, spacing: spacing)
    }
    
    static func labelItem(_ text: String, font: UIFont, color: UIColor, spacing: CGFloat) -> InstructionItem {
        let label = UILabel(label: text, font: font, color: color)
        label.numberOfLines = 0
        return InstructionItem(view: label, spacing: spacing)
    }
}

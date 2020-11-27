import SnapKit
import UIKit

class Checkbox: UIView {
    enum Text: String, Localizable {
        case AccessibilityValueUnchecked
        case AccessibilityValueChecked
        case AccessibilityHint
    }
    
    private let acceptButton = UIButton()
    private let labelView: UILabel
    private let tapped: (Bool) -> ()
    
    private(set) var labelStartConstraint: ConstraintItem!
    
    var isChecked: Bool {
        acceptButton.isSelected
    }
    
    init(label: String, tapped: @escaping (Bool) -> ()) {
        self.tapped = tapped
        
        self.labelView = UILabel(label: label,
                                 font: UIFont.bodySmall,
                                 color: UIColor.Greyscale.darkGrey)
        
        super.init(frame: .zero)

        acceptButton.isSelected = false
        acceptButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        acceptButton.backgroundColor = .clear
        acceptButton.layer.cornerRadius = 5
        acceptButton.layer.borderWidth = 2
        acceptButton.layer.borderColor = UIColor.Primary.blue.cgColor
        acceptButton.setBackgroundImage(UIImage(named: "check")!.withTintColor(UIColor.Greyscale.white), for: .selected)
        acceptButton.imageView?.contentMode = .scaleAspectFit
        acceptButton.backgroundColor = acceptButton.isSelected ?
            UIColor.Primary.blue :
            .clear
        
        self.addSubview(acceptButton)

        acceptButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.width.height.equalTo(22)
            make.bottom.lessThanOrEqualToSuperview().offset(20)
        }
        
        labelView.numberOfLines = 0
        self.addSubview(labelView)
        labelStartConstraint = labelView.snp.left
        labelView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(acceptButton.snp.right).offset(10)
            make.right.equalToSuperview().offset(-20)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleTapped))
        labelView.addGestureRecognizer(tap)

        labelView.isUserInteractionEnabled = true
        acceptButton.isAccessibilityElement = false
        labelView.isAccessibilityElement = false
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityValue = Text.AccessibilityValueUnchecked.localized
        accessibilityHint = Text.AccessibilityHint.localized
    }
    
    override func accessibilityActivate() -> Bool {
        toggleTapped()
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleTapped() {
        acceptButton.isSelected = !acceptButton.isSelected
        UISelectionFeedbackGenerator().selectionChanged()
        acceptButton.backgroundColor = acceptButton.isSelected ? UIColor.Primary.blue : .clear
        tapped(isChecked)
        let accessibilityValue: Text = isChecked ? .AccessibilityValueChecked : .AccessibilityValueUnchecked
        self.accessibilityValue = accessibilityValue.localized
    }
}

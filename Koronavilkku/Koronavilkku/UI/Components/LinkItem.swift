import Foundation
import UIKit
import SnapKit

typealias TapHandler = () -> ()

class LinkItem: UIButton {

    private let tapped: TapHandler
    private let valueLabel: UILabel
    private var valueMarginConstraint: Constraint? = nil
    private var tapRecognizer: UITapGestureRecognizer!

    init(title: String, linkName: String? = nil, value: String? = nil, tapped: TapHandler? = nil, url: URL? = nil) {
        guard tapped != nil || url != nil else { fatalError("Either argument tapped or url must be defined") }
        
        self.tapped = tapped ?? {
            LinkHandler.shared.open(url!)
        }
        self.valueLabel = UILabel(label: value ?? "", font: UIFont.bodySmall, color: UIColor.Greyscale.darkGrey)
        
        super.init(frame: .zero)

        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        accessibilityTraits = .link

        let indicator = UIImageView(image: UIImage(named: "chevron-right")!)
        addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(CGSize(width: 8, height: 14))
        }

        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            valueMarginConstraint = make.trailing.equalTo(indicator.snp.leading).offset(0).constraint
            make.centerY.equalToSuperview()
        }
        updateValueConstraint()
        
        let verticalContainer = UIView()
        addSubview(verticalContainer)
        verticalContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(valueLabel.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualTo(12)
            make.bottom.greaterThanOrEqualTo(-12)
        }

        let titleLabel = UILabel(label: title, font: UIFont.bodySmall, color: UIColor.Greyscale.black)
        titleLabel.numberOfLines = 0
        verticalContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        if let linkName = linkName {
            let linkLabel = UILabel(label: linkName, font: UIFont.labelTertiary, color: UIColor.Primary.blue)
            linkLabel.numberOfLines = 0
            verticalContainer.addSubview(linkLabel)
            linkLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }

        } else {
            titleLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
        
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
        }
        
        setEnabled(true)
        
        accessibilityLabel = title
        accessibilityValue = value ?? linkName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapGesture() {
        self.tapped()
    }
    
    private func updateValueConstraint() {
        let hasValue = valueLabel.text?.count ?? 0 > 0
        valueMarginConstraint?.update(offset: hasValue ? -18 : 0)
    }
    
    func setValue(value: String?) {
        accessibilityValue = value
        valueLabel.text = value
        updateValueConstraint()
    }
    
    func setEnabled(_ enabled: Bool) {
        alpha = enabled ? 1.0 : 0.5
        
        if enabled {
            self.addGestureRecognizer(tapRecognizer)
        } else {
            self.removeGestureRecognizer(tapRecognizer)
        }
    }
}

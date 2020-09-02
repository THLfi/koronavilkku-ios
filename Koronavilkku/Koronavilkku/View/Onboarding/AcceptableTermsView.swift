
import Foundation
import UIKit
import SnapKit

protocol AcceptDelegate: NSObjectProtocol {
    func statusChanged()
}

protocol AcceptableView {
    var delegate: AcceptDelegate? { get set }
    var accepted: Bool { get }
}

class LinkTapGestureRecognizer: UITapGestureRecognizer {
    var url: URL?
}

class AcceptableTermsView: CardElement, AcceptableView {
    
    weak var delegate: AcceptDelegate?
    
    var accepted: Bool = false
        
    private let acceptButton = UIButton()
    private let touchArea = UIView()
    private let label: String
    private var externalLinkCaption: String?
    private var externalLinkUrl: URL?
    
    init(label: String, externalLinkCaption: String? = nil, externalLinkUrl: URL? = nil) {
        self.label = label
        self.externalLinkCaption = externalLinkCaption
        self.externalLinkUrl = externalLinkUrl
        
        super.init()
        
        initUI()
        
        self.layer.shadowColor = UIColor.Greyscale.darkGrey.cgColor
        self.layer.borderColor = UIColor(red: 0.938, green: 0.938, blue: 0.938, alpha: 1).cgColor
        self.layer.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        self.backgroundColor = UIColor.Greyscale.white
        
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

        }
        
        let textLabel = UILabel(label: self.label,
                                font: UIFont.bodySmall,
                                color: UIColor.Greyscale.darkGrey)
        textLabel.numberOfLines = 0
        self.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(acceptButton.snp.right).offset(10)
            make.right.equalToSuperview().offset(-20)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleTapped))
        touchArea.addGestureRecognizer(tap)
        self.addSubview(touchArea)
        
        let bottomMargin: CGFloat = 20
        let contentBottom: ConstraintItem

        if let caption = externalLinkCaption, let url = externalLinkUrl {
            let spacing: CGFloat = 10
            let linkLabel = LinkLabel(label: caption,
                                    font: UIFont.linkLabel,
                                    color: UIColor.Primary.blue,
                                    url: url)
            linkLabel.contentInset = UIEdgeInsets(top: -spacing, left: 0, bottom: -bottomMargin, right: 0)
            linkLabel.accessibilityTraits = .link
            self.addSubview(linkLabel)
            
            linkLabel.snp.makeConstraints { make in
                make.left.equalTo(acceptButton.snp.right).offset(10)
                make.top.equalTo(textLabel.snp.bottom).offset(spacing)
                make.left.equalTo(textLabel)
                make.right.equalTo(textLabel)
            }
            contentBottom = linkLabel.snp.bottom
            
            touchArea.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(linkLabel.snp.top).offset(-spacing)
            }

        } else {
            contentBottom = textLabel.snp.bottom
            
            touchArea.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }

        self.snp.makeConstraints { make in
            make.bottom.equalTo(contentBottom).offset(bottomMargin)
        }
        
        acceptButton.isAccessibilityElement = false
        textLabel.isAccessibilityElement = false
        touchArea.isAccessibilityElement = true
        touchArea.accessibilityTraits = .button
        touchArea.accessibilityLabel = textLabel.text
    }
    
    @objc func toggleTapped() {
        acceptButton.isSelected = !acceptButton.isSelected
        acceptButton.backgroundColor = acceptButton.isSelected ? UIColor.Primary.blue : .clear
        
        if acceptButton.isSelected {
            touchArea.accessibilityTraits.insert(.selected)
        } else {
            touchArea.accessibilityTraits.remove(.selected)
        }
        
        Log.d("Checkbox button tapped")
        self.accepted = acceptButton.isSelected
        self.delegate?.statusChanged()
    }
}

#if DEBUG
import SwiftUI

struct AcceptableTermsViewPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: AcceptableTermsView(label: "Olen lukenut ja hyväksyn palvelun käyttöehdot.",
                                 externalLinkCaption: "Lue käyttöehdot",
                                 externalLinkUrl: URL(string: "http://www.thl.fi")),
        width: 295,
        height: 250
        
    )
}
#endif

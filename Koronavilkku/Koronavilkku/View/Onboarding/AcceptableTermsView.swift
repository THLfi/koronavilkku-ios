
import Foundation
import UIKit
import SnapKit

protocol AcceptDelegate: AnyObject {
    func statusChanged()
    func openLink(url: URL)
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
        
    private var checkbox: Checkbox!
    private var externalLinkCaption: String?
    private var externalLinkUrl: URL?
    
    init(label: String, externalLinkCaption: String? = nil, externalLinkUrl: URL? = nil) {
        self.externalLinkCaption = externalLinkCaption
        self.externalLinkUrl = externalLinkUrl
        
        super.init()
        
        initUI(label: label)
        
        self.layer.borderColor = UIColor.Greyscale.backdropGrey.cgColor
        self.layer.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI(label: String) {
        self.backgroundColor = UIColor.Greyscale.white
        let contentBottom: ConstraintItem
        let bottomMargin: CGFloat
        
        checkbox = Checkbox(label: label) { [unowned self] checked in
            self.accepted = checked
            self.delegate?.statusChanged()
        }

        self.addSubview(checkbox)
        
        checkbox.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        if let caption = externalLinkCaption, let url = externalLinkUrl {
            let spacing: CGFloat = 10
            let linkLabel = LinkLabel(label: caption,
                                      font: UIFont.linkLabel,
                                      color: UIColor.Primary.blue) { [unowned self] in
                self.delegate?.openLink(url: url)
            }

            linkLabel.contentInset = UIEdgeInsets(top: -spacing, left: 0, bottom: -spacing * 2, right: 0)
            linkLabel.accessibilityTraits = .link
            self.addSubview(linkLabel)

            linkLabel.snp.makeConstraints { make in
                make.top.equalTo(checkbox.snp.bottom).offset(-10)
                make.left.equalTo(checkbox.labelStartConstraint)
                make.right.equalTo(checkbox).offset(-20)
            }

            contentBottom = linkLabel.snp.bottom
            bottomMargin = 20
        } else {
            contentBottom = checkbox.snp.bottom
            bottomMargin = 0
        }

        self.snp.makeConstraints { make in
            make.bottom.equalTo(contentBottom).offset(bottomMargin)
        }
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

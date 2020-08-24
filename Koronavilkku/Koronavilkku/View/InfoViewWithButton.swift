import Foundation
import UIKit
import SnapKit

class InfoViewWithButton: CardElement {
    
    let buttonTapped: () -> ()
    let helperText: String?
    let title: String
    let descriptionText: String
    let buttonTitle: String
    let bottomText: String?
    
    init(helperText: String? = nil,
         title: String,
         descriptionText: String,
         buttonTitle: String,
         bottomText: String?,
         buttonTapped: @escaping () -> ()) {
        self.helperText = helperText
        self.title = title
        self.descriptionText = descriptionText
        self.buttonTitle = buttonTitle
        self.bottomText = bottomText
        self.buttonTapped = buttonTapped
        super.init()
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        let titleLabel = UILabel(label: self.title,
                                 font: UIFont.heading2,
                                 color: UIColor.Greyscale.black)
        titleLabel.numberOfLines = 0
        titleLabel.setLineHeight(0.9)
        
        let descriptionLabel = UILabel(label: descriptionText,
                                       font: UIFont.bodySmall,
                                       color: UIColor.Greyscale.black)
        descriptionLabel.numberOfLines = 0
        
        let button = RoundedButton(title: buttonTitle, action: {
            self.buttonTapped()
        })
    
        let contentView = UIView()
        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        var top = contentView.snp.top
        
        if let helperText = self.helperText {
            let helperLabel = UILabel(label: helperText.uppercased(),
                                      font: UIFont.heading5,
                                      color: UIColor.Primary.blue)
            top = contentView.appendView(helperLabel, top: top)
        }

        top = contentView.appendView(titleLabel, top: top)
        top = contentView.appendView(descriptionLabel, spacing: 10, top: top)
        top = contentView.appendView(button, spacing: 20, top: top)
        
        if let bottomText = self.bottomText {
            let bottomLabel = UILabel(label: bottomText,
                                      font: UIFont.labelTertiary,
                                      color: UIColor.Greyscale.black)
            bottomLabel.numberOfLines = 0
            bottomLabel.textAlignment = .center
            top = contentView.appendView(bottomLabel, spacing: 20, top: top)
        }
        
        contentView.subviews.last!.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }
}

#if DEBUG
import SwiftUI

struct ContactViewPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: InfoViewWithButton(helperText: "helper text",
                                title: "Title String",
                                descriptionText: "description text",
                                buttonTitle: "Button title",
                                bottomText: "Bottom text",
                                buttonTapped: {}),
        width: 335,
        height: 292
    )
}
#endif

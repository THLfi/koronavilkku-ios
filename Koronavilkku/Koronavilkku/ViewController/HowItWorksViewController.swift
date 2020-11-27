import Foundation
import UIKit
import SnapKit

class HowItWorksViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        let content = view.addScrollableContentView(
            backgroundColor: .white,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        let closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        let titleLabel = InstructionsView.labelItem(Translation.GuideTitle,
                                                    font: UIFont.heading2,
                                                    color: UIColor.Greyscale.black,
                                                    spacing: 30)
        titleLabel.view.accessibilityTraits = .header

        let items = [
            titleLabel,
            textLabel(Translation.GuideText),
            imageItem("device-codes"),
            subtitleLabel(Translation.GuideSeedTitle),
            textLabel(Translation.GuideSeedText),
            imageItem("exchange-codes"),
            subtitleLabel(Translation.GuideExchangeTitle),
            textLabel(Translation.GuideExchangeText),
            imageItem("compare-codes"),
            subtitleLabel(Translation.GuideCompareTitle),
            textLabel(Translation.GuideCompareText),
            imageItem("notifications"),
            subtitleLabel(Translation.GuideNotificationTitle),
            textLabel(Translation.GuideNotificationText),
            imageItem("broadcasting-infection"),
            subtitleLabel(Translation.GuideDiagnosisTitle),
            textLabel(Translation.GuideDiagnosisText),
            subtitleLabel(Translation.GuidePrivacyTitle),
            textLabel(Translation.GuidePrivacyText),
            bulletItem(Translation.GuidePrivacyItem1, spacing: 20),
            bulletItem(Translation.GuidePrivacyItem2),
            bulletItem(Translation.GuidePrivacyItem3),
        ]

        let topConstraint = InstructionsView.layoutItems(items, contentView: content)
        
        let backButton = RoundedButton(title: Translation.GuideButtonBack.localized, action: { [unowned self] in self.close() })
        content.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topConstraint).offset(30)
            make.bottom.equalToSuperview()
        }
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: {})
    }

    private func bulletItem(_ text: Translation, spacing: CGFloat = 10) -> InstructionItem {
        let bullet = BulletItem(text: text.localized, textColor: UIColor.Greyscale.darkGrey)
        return InstructionItem(view: bullet, spacing: spacing)
    }

    private func subtitleLabel(_ text: Translation) -> InstructionItem {
        InstructionsView.labelItem(text, font: UIFont.heading4, color: UIColor.Greyscale.black, spacing: 20)
    }

    private func listTitleLabel(_ text: Translation) -> InstructionItem {
        return InstructionsView.labelItem(text, font: UIFont.heading5, color: UIColor.Greyscale.black, spacing: 10)
    }
    
    private func textLabel(_ text: Translation) -> InstructionItem {
        return InstructionsView.labelItem(text, font: UIFont.bodySmall, color: UIColor.Greyscale.darkGrey, spacing: 10)
    }
    
    private func imageItem(_ imageName: String) -> InstructionItem {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        return InstructionItem(view: imageView, makeConstraints: { topConstraint, make in
            make.top.equalTo(topConstraint).offset(30)
            make.height.lessThanOrEqualTo(214)
            make.centerX.equalToSuperview()
        })
    }
}

#if DEBUG
import SwiftUI

struct HowItWorksViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: HowItWorksViewController())
}
#endif

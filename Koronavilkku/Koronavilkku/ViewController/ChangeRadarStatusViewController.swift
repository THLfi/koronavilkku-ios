import Foundation
import UIKit
import SnapKit

class ChangeRadarStatusViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil

        initUI()
    }
    
    private func initUI() {
        let isOn = LocalStore.shared.uiStatus == .on
        let title, text, attentionText, buttonTitle, buttonLabel: Translation
        let info: Translation?
        let titleColor: UIColor
        let buttonColor: UIColor
        let buttonHighlightedColor: UIColor
        
        if isOn {
            title = .DisableTitle
            titleColor = UIColor.Greyscale.black
            text = .DisableText
            attentionText = .DisableAttentionText
            buttonTitle = .DisableButtonTitle
            buttonLabel = .DisableButtonLabel
            buttonColor = UIColor.Primary.red
            buttonHighlightedColor = UIColor.Primary.red
            info = .DisableInfo
        } else {
            title = .EnableTitle
            titleColor = UIColor.Primary.red
            text = .EnableText
            attentionText = .EnableAttentionText
            buttonTitle = .EnableButtonTitle
            buttonLabel = .EnableButtonLabel
            buttonColor = UIColor.Primary.blue
            buttonHighlightedColor = UIColor.Secondary.buttonHighlightedBackground
            info = nil
        }
        
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        var topConstraint = content.snp.top
        
        func appendView(_ view: UIView, spacing: CGFloat) {
            topConstraint = content.appendView(view, spacing: spacing, top: topConstraint)
        }

        let titleLabel = UILabel(label: title.localized, font: .heading2, color: titleColor)
        titleLabel.numberOfLines = 0
        appendView(titleLabel, spacing: 30)
        
        let textLabel = UILabel(label: text.localized, font: .heading4, color: UIColor.Greyscale.black)
        textLabel.numberOfLines = 0
        appendView(textLabel, spacing: 20)

        if let info = info {
            let infoLabel = UILabel(label: info.localized, font: .bodySmall, color: UIColor.Greyscale.darkGrey)
            infoLabel.numberOfLines = 0
            appendView(infoLabel, spacing: 20)
        }
        
        appendView(AttentionCard(text: attentionText.localized), spacing: 20)

        let buttonTitleLabel = UILabel(label: buttonTitle.localized.uppercased(), font: .heading5, color: UIColor.Greyscale.black)
        buttonTitleLabel.numberOfLines = 0
        buttonTitleLabel.textAlignment = .center
        appendView(buttonTitleLabel, spacing: 30)

        let button = RoundedButton(title: buttonLabel.localized, backgroundColor: buttonColor, highlightedBackgroundColor: buttonHighlightedColor, action: { [weak self] in
            self?.setStatus(enabled: isOn ? false : true)
        })
        content.addSubview(button)
        appendView(button, spacing: 20)
        
        button.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setStatus(enabled: Bool) {
        let exposureRepository = Environment.default.exposureRepository
        
        let action = {
            exposureRepository.setStatus(enabled: enabled)
            self.navigationController?.popViewController(animated: true)
        }
        
        if !enabled {
            showConfirmation(title: Translation.DisableConfirmTitle.localized,
                             message: Translation.DisableConfirmText.localized,
                             okText: Translation.DisableConfirmButton.localized,
                             cancelText: Translation.DisableCancelButton.localized,
                             handler: { confirmed in
                                if confirmed { action() }
                             })
            
        } else {
            action()
        }
    }
}

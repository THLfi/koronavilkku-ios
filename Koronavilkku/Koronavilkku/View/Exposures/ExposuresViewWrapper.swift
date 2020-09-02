
import Foundation
import UIKit
import Combine

protocol ExposuresViewDelegate: NSObjectProtocol {
    func showHowItWorks()
    func makeContact()
}

class ExposuresViewWrapper: UIView {
    enum HasExposureText : String, Localizable {
        case Heading
        case ContactCardTitle
        case ContactCardText
        case ContactButtonTitle
        case InstructionsTitle
        case InstructionsSymptoms
        case InstructionsSymptomsText
        case InstructionsDistancing
        case InstructionsHygiene
        case InstructionsAvoidTravel
        case InstructionsShopping
        case InstructionsCoughing
        case InstructionsRemoteWork
        case ExposureDisclaimer
    }
    
    enum NoExposuresText : String, Localizable {
        case Heading
        case Subtitle
        case DisclaimerText
    }
    
    weak var delegate: ExposuresViewDelegate?
    let lastCheckedView = ExposuresLastCheckedView()
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(hasExposures: Bool) {
        self.removeAllSubviews()
        
        if hasExposures {
            createExposureView()
        } else {
            createNoExposuresView()
        }
    }
    
    private func createExposureView() {
        var top = self.snp.top
        
        let exposuresLabel = UILabel(label: HasExposureText.Heading.localized,
                                    font: UIFont.heading4,
                                    color: UIColor.Greyscale.black)
        exposuresLabel.numberOfLines = 0
        top = appendView(exposuresLabel, spacing: 0, top: top)

        let contactView = InfoViewWithButton(title: HasExposureText.ContactCardTitle.localized,
                                             descriptionText: HasExposureText.ContactCardText.localized,
                                             buttonTitle: HasExposureText.ContactButtonTitle.localized,
                                             bottomText: nil,
                                             buttonTapped: { [unowned self] in self.delegate?.makeContact() })
        top = appendView(contactView, spacing: 20, top: top)

        let instructionsTitle = UILabel(label: HasExposureText.InstructionsTitle.localized, font: .heading3, color: UIColor.Greyscale.black)
        instructionsTitle.numberOfLines = 0
        top = appendView(instructionsTitle, spacing: 30, top: top)
        
        func bulletItem(_ text: HasExposureText) -> BulletListParagraph {
            return BulletListParagraph(content: text.localized, textColor: UIColor.Greyscale.black)
        }

        let item1 = bulletItem(.InstructionsSymptoms).get().toLabel()
        top = appendView(item1, spacing: 20, top: top)

        let details1 = IndentedParagraph(content: HasExposureText.InstructionsSymptomsText.localized,
                                         textColor: UIColor.Greyscale.darkGrey)
        top = appendView(details1.get().toLabel(), spacing: 10, top: top)
        
        let bulletList = [
            .InstructionsDistancing,
            .InstructionsHygiene,
            .InstructionsAvoidTravel,
            .InstructionsShopping,
            .InstructionsCoughing,
            .InstructionsRemoteWork,
        ].map { bulletItem($0) }.asMutableAttributedString().toLabel()

        top = appendView(bulletList, spacing: 10, top: top)
         
        bulletList.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualToSuperview()
        }

        let divider = UIView.createDivider()
        top = appendView(divider, spacing: 30, top: top)

        let disclaimer = UILabel(label: HasExposureText.ExposureDisclaimer.localized,
                                 font: UIFont.bodySmall,
                                 color: UIColor.Greyscale.darkGrey)
        disclaimer.numberOfLines = 0
        top = appendView(disclaimer, spacing: 30, top: top)
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(disclaimer).offset(30)
        }
    }
    
    private func createNoExposuresView() {
        var top = self.snp.top

        let noExposuresHeader = UILabel(label: NoExposuresText.Heading.localized,
                                        font: UIFont.heading2,
                                        color: UIColor.Greyscale.black)
        noExposuresHeader.numberOfLines = 0
        top = appendView(noExposuresHeader, top: top)
        top = appendView(lastCheckedView, spacing: 10, top: top)
        
        let noExposuresLabel = UILabel(label: NoExposuresText.Subtitle.localized,
                                       font: UIFont.heading4,
                                       color: UIColor.Greyscale.black)
        noExposuresLabel.numberOfLines = 0
        top = appendView(noExposuresLabel, spacing: 30, top: top)
        
        let helperLabel = UILabel(label: NoExposuresText.DisclaimerText.localized,
                                  font: UIFont.bodySmall,
                                  color: UIColor.Greyscale.black)
        helperLabel.numberOfLines = 0
        top = appendView(helperLabel, spacing: 10, top: top)
        
        let howItWorksLink = InternalLinkLabel(label: Translation.HowItWorksButton.localized,
                                           font: UIFont.labelSecondary,
                                           color: UIColor.Primary.blue,
                                           linkTapped: { [unowned self] in self.delegate?.showHowItWorks() },
                                           underline: false)
        top = appendView(howItWorksLink, spacing: 8, top: top)
        
        howItWorksLink.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(35)
            make.bottom.equalToSuperview()
        }
    }
}

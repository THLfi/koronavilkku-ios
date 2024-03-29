import SnapKit
import UIKit

class HasExposuresView : ExposuresView, LocalizedView {
    enum Text : String, Localizable {
        case Heading
        case ContactCardTitle
        case ContactCardText
        case ContactButtonTitle
        case ExposuresButtonTitle
        case ExposuresButtonNotificationCount
        case InstructionsTitle
        case InstructionsLede
        case InstructionsDistancing
        case InstructionsHygiene
        case InstructionsAvoidTravel
        case InstructionsShopping
        case InstructionsCoughing
        case InstructionsRemoteWork
        case InstructionsWhenAbroad
        case TestingTitle
        case TestingBody
        case InfoLinkTitle
        case InfoLinkSubtitle
        case InfoLinkURL
    }

    init(notificationCount: Int?) {
        super.init(frame: .zero)
        
        var top = self.snp.top
        
        let exposuresLabel = UILabel(label: text(key: .Heading),
                                     font: .heading4,
                                     color: UIColor.Greyscale.black)
        exposuresLabel.numberOfLines = 0
        top = appendView(exposuresLabel, spacing: 0, top: top)

        let contactView = InfoViewWithButton(title: text(key: .ContactCardTitle),
                                             titleFont: .heading3,
                                             descriptionText: text(key: .ContactCardText),
                                             buttonTitle: text(key: .ContactButtonTitle),
                                             bottomText: nil) { [unowned self] in
            self.delegate?.makeContact()
        }
        
        top = appendView(contactView, spacing: 20, top: top)
        
        if let notificationCount = notificationCount {
            let button = InfoButton(title: text(key: .ExposuresButtonTitle),
                                    subtitle: text(key: .ExposuresButtonNotificationCount,
                                                   with: notificationCount)) { [unowned self] in
                self.delegate?.showNotificationList()
            }
            
            top = appendView(button, spacing: 20, top: top)
        }

        let instructionsTitle = UILabel(label: text(key: .InstructionsTitle),
                                        font: .heading3,
                                        color: UIColor.Greyscale.black)
        
        instructionsTitle.numberOfLines = 0
        top = appendView(instructionsTitle, spacing: 30, top: top)
        
        let instructionsLede = UILabel(label: text(key: .InstructionsLede),
                                       font: .bodySmall,
                                       color: UIColor.Greyscale.black)
        
        instructionsLede.numberOfLines = 0
        top = appendView(instructionsLede, spacing: 18, top: top)
        
        let bulletList = UIView()
        top = appendView(bulletList, spacing: 10, top: top)
        
        let lastBulletBottom = [
            .InstructionsDistancing,
            .InstructionsHygiene,
            .InstructionsAvoidTravel,
            .InstructionsShopping,
            .InstructionsCoughing,
            .InstructionsRemoteWork,
        ].reduce(bulletList.snp.top) { (top, text: Text) -> ConstraintItem in
            let bullet = BulletItem(text: text.localized)
            return bulletList.appendView(bullet, spacing: 10, top: top)
        }
        
        bulletList.snp.makeConstraints { make in
            make.bottom.equalTo(lastBulletBottom)
        }
        
        let whenAboardLabel = UILabel(label: text(key: .InstructionsWhenAbroad),
                                      font: .bodySmall,
                                      color: UIColor.Greyscale.black)
        whenAboardLabel.numberOfLines = 0
        top = appendView(whenAboardLabel, spacing: 20, top: top)

        
        let vaccinatedTitle = UILabel(label: text(key: .TestingTitle),
                                      font: .heading3,
                                      color: .Greyscale.black)
        
        vaccinatedTitle.numberOfLines = 0
        top = appendView(vaccinatedTitle, spacing: 20, top: top)
        
        let vaccinatedBody = UILabel(label: text(key: .TestingBody),
                                     font: .bodySmall,
                                     color: .Greyscale.black)
        
        vaccinatedBody.numberOfLines = 0
        top = appendView(vaccinatedBody, spacing: 20, top: top)
        
        let infoLink = LinkItemCard(title: text(key: .InfoLinkTitle),
                                    linkName: text(key: .InfoLinkSubtitle)) { [unowned self] in
            self.delegate?.openLink(url: URL(string: text(key: .InfoLinkURL))!)
        }
        
        top = appendView(infoLink, spacing: 20, top: top)

        self.snp.makeConstraints { make in
            make.bottom.equalTo(infoLink.snp.bottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

struct HasExposuresView_Preview: PreviewProvider {
    static var previews: some View = Group {
        createPreviewInContainer(for: HasExposuresView(notificationCount: nil), width: 375, height: 1300)

        createPreviewInContainer(for: HasExposuresView(notificationCount: 10), width: 375, height: 1400)
    }
}

#endif

import SnapKit
import UIKit

class InfoButton : CardElement {
    private var titleView: UILabel!
    private var subtitleView: UILabel!
    private var tapRecognizer: UITapGestureRecognizer!
    private let tapped: () -> ()
    
    var title: String {
        didSet {
            titleView.text = title
            accessibilityLabel = title
        }
    }
    
    var subtitle: String {
        didSet {
            subtitleView.text = subtitle
            accessibilityValue = subtitle
        }
    }
    
    init(title: String, subtitle: String, tapped: @escaping () -> ()) {
        self.title = title
        self.subtitle = subtitle
        self.tapped = tapped
        super.init()

        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler))
        self.addGestureRecognizer(self.tapRecognizer)
        
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
        self.accessibilityValue = subtitle
        
        let imageView = UIImageView(image: UIImage(named: "info-mark")?.withTintColor(UIColor.Primary.blue))
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        let titleView = UILabel(label: title, font: .bodySmall, color: UIColor.Greyscale.black)
        titleView.numberOfLines = 0
        addSubview(titleView)
        
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.left.equalToSuperview().inset(20)
            make.right.equalTo(imageView.snp.left).offset(-10)
        }
        
        let subtitleView = UILabel(label: subtitle, font: .labelTertiary, color: UIColor.Greyscale.darkGrey)
        subtitleView.numberOfLines = 0
        addSubview(subtitleView)

        subtitleView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(2)
            make.left.equalToSuperview().inset(20)
            make.right.equalTo(imageView.snp.left).offset(-10)
            make.bottom.equalToSuperview().inset(13)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapGestureHandler() {
        tapped()
    }
}

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
        case InstructionsSymptoms
        case InstructionsDistancing
        case InstructionsHygiene
        case InstructionsAvoidTravel
        case InstructionsShopping
        case InstructionsCoughing
        case InstructionsRemoteWork
        case InstructionsWhenAbroad
    }

    init(notificationCount: Int?) {
        super.init(frame: .zero)
        
        var top = self.snp.top
        
        let exposuresLabel = label(text: .Heading)
        exposuresLabel.font = .heading4
        exposuresLabel.textColor = UIColor.Greyscale.black
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
            .InstructionsSymptoms,
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
        
        let whenAboardLabel = label(text: .InstructionsWhenAbroad)
        whenAboardLabel.font = .bodySmall
        whenAboardLabel.textColor = UIColor.Greyscale.black
        whenAboardLabel.numberOfLines = 0
        top = appendView(whenAboardLabel, spacing: 20, top: top)

        self.snp.makeConstraints { make in
            make.bottom.equalTo(whenAboardLabel.snp.bottom)
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
        createPreviewInContainer(for: HasExposuresView(notificationCount: nil), width: 375, height: 1000)

        createPreviewInContainer(for: HasExposuresView(notificationCount: 10), width: 375, height: 1000)
    }
}

#endif
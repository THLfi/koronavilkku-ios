import Combine
import SnapKit
import UIKit

protocol ExposuresViewDelegate: AnyObject {
    func showHowItWorks()
    func makeContact()
    func startManualCheck()
    func showNotificationList()
}

class CheckDelayedView : CardElement {
    var detectionRunning: Bool = false {
        didSet {
            button.isLoading = detectionRunning
        }
    }
    
    private let button: RoundedButton!
    
    init(buttonAction: @escaping () -> ()) {
        self.button = RoundedButton(title: ExposuresElement.Text.ButtonCheckNow.localized,
                                    backgroundColor: UIColor.Primary.blue,
                                    highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground,
                                    action: buttonAction)
        super.init()
        createUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createUI() {
        let label = UILabel(label: ExposuresElement.Text.BodyExposureCheckDelayed.localized, font: .labelTertiary, color: UIColor.Greyscale.black)
        label.numberOfLines = 0
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(20)
        }
        
        addSubview(button)
        
        button.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(30)
        }
    }
}

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

class ExposuresViewWrapper: UIView {
    enum HasExposureText : String, Localizable {
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
    
    enum NoExposuresText : String, Localizable {
        case Heading
        case Subtitle
        case DisclaimerText
    }
    
    weak var delegate: ExposuresViewDelegate?
    
    private var lastCheckedView: ExposuresLastCheckedView?
    private var checkDelayedView: CheckDelayedView?
    
    var timeFromLastCheck: TimeInterval? {
        didSet {
            guard let timeFromLastCheck = timeFromLastCheck, timeFromLastCheck != oldValue else { return }
            lastCheckedView?.timeFromLastCheck = timeFromLastCheck
        }
    }
    
    var exposureStatus: ExposureStatus? {
        didSet {
            guard let exposureStatus = exposureStatus, exposureStatus != oldValue else { return }
            render()
        }
    }
    
    var detectionStatus: DetectionStatus? {
        didSet {
            if detectionStatus?.manualCheckAllowed() != oldValue?.manualCheckAllowed() {
                render()
            }
            
            if let detectionStatus = detectionStatus {
                self.checkDelayedView?.detectionRunning = detectionStatus.running
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render() {
        self.checkDelayedView = nil
        self.removeAllSubviews()
        
        if case .exposed(let notificationCount) = exposureStatus {
            createExposureView(notificationCount: notificationCount)
        } else {
            createNoExposuresView()
        }
    }
    
    private func createExposureView(notificationCount: Int?) {
        var top = self.snp.top
        
        let exposuresLabel = UILabel(label: HasExposureText.Heading.localized,
                                    font: UIFont.heading4,
                                    color: UIColor.Greyscale.black)
        exposuresLabel.numberOfLines = 0
        top = appendView(exposuresLabel, spacing: 0, top: top)

        let contactView = InfoViewWithButton(title: HasExposureText.ContactCardTitle.localized,
                                             titleFont: .heading3,
                                             descriptionText: HasExposureText.ContactCardText.localized,
                                             buttonTitle: HasExposureText.ContactButtonTitle.localized,
                                             bottomText: nil) { [unowned self] in
            self.delegate?.makeContact()
        }
        
        top = appendView(contactView, spacing: 20, top: top)
        
        if let notificationCount = notificationCount {
            let button = InfoButton(title: HasExposureText.ExposuresButtonTitle.localized,
                                    subtitle: HasExposureText.ExposuresButtonNotificationCount.localized(with: notificationCount)) { [unowned self] in
                self.delegate?.showNotificationList()
            }
            
            top = appendView(button, spacing: 20, top: top)
        }

        let instructionsTitle = UILabel(label: HasExposureText.InstructionsTitle.localized, font: .heading3, color: UIColor.Greyscale.black)
        instructionsTitle.numberOfLines = 0
        top = appendView(instructionsTitle, spacing: 30, top: top)
        
        let instructionsLede = UILabel(label: HasExposureText.InstructionsLede.localized, font: .bodySmall, color: UIColor.Greyscale.black)
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
        ].reduce(bulletList.snp.top) { (top, text: HasExposureText) -> ConstraintItem in
            let bullet = BulletItem(text: text.localized)
            return bulletList.appendView(bullet, spacing: 10, top: top)
        }
        
        bulletList.snp.makeConstraints { make in
            make.bottom.equalTo(lastBulletBottom)
        }
        
        let whenAboardLabel = UILabel(label: HasExposureText.InstructionsWhenAbroad.localized,
                                      font: .bodySmall,
                                      color: UIColor.Greyscale.black)
        whenAboardLabel.numberOfLines = 0
        top = appendView(whenAboardLabel, spacing: 20, top: top)

        self.snp.makeConstraints { make in
            make.bottom.equalTo(whenAboardLabel.snp.bottom)
        }
    }
    
    private func createNoExposuresView() {
        var top = self.snp.top

        let noExposuresHeader = UILabel(label: NoExposuresText.Heading.localized,
                                        font: UIFont.heading2,
                                        color: UIColor.Greyscale.black)
        noExposuresHeader.numberOfLines = 0
        top = appendView(noExposuresHeader, top: top)
        
        self.lastCheckedView = ExposuresLastCheckedView(value: timeFromLastCheck)
        top = appendView(self.lastCheckedView!, spacing: 10, top: top)
        
        if detectionStatus?.manualCheckAllowed() == true {
            self.checkDelayedView = CheckDelayedView() { [unowned self] in
                self.delegate?.startManualCheck()
            }
            
            top = appendView(self.checkDelayedView!, spacing: 30, top: top)
        }
        
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

#if DEBUG

import SwiftUI

struct ExposuresViewWrapper_Preview: PreviewProvider {
    static func createView(customize: (ExposuresViewWrapper) -> Void) -> ExposuresViewWrapper {
        let view = ExposuresViewWrapper()
        customize(view)
        return view
    }
    
    static var previews: some View = Group {
        createPreviewInContainer(for: createView {
            $0.exposureStatus = .unexposed
        }, width: 375, height: 300)

        createPreviewInContainer(for: createView {
            $0.exposureStatus = .unexposed
            $0.detectionStatus = .init(status: .on, delayed: true, running: true)
        }, width: 375, height: 320)
        
        createPreviewInContainer(for: createView {
            $0.exposureStatus = .unexposed
            $0.detectionStatus = .init(status: .on, delayed: true, running: false)
        }, width: 375, height: 320)

        createPreviewInContainer(for: createView {
            $0.exposureStatus = .exposed(notificationCount: nil)
        }, width: 375, height: 1000)

        createPreviewInContainer(for: createView {
            $0.exposureStatus = .exposed(notificationCount: 10)
        }, width: 375, height: 1000)
    }
}

#endif

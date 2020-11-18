
import Foundation
import UIKit
import Combine

protocol ExposuresViewDelegate: AnyObject {
    func showHowItWorks()
    func makeContact()
    func startManualCheck()
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
    }
    
    enum NoExposuresText : String, Localizable {
        case Heading
        case Subtitle
        case DisclaimerText
    }
    
    weak var delegate: ExposuresViewDelegate?
    
    private lazy var lastCheckedView = ExposuresLastCheckedView(value: timeFromLastCheck)
    private lazy var checkDelayedView = CheckDelayedView() { [unowned self] in
        self.delegate?.startManualCheck()
    }
    
    var timeFromLastCheck: TimeInterval? {
        didSet {
            guard let timeFromLastCheck = timeFromLastCheck, timeFromLastCheck != oldValue else { return }
            lastCheckedView.timeFromLastCheck = timeFromLastCheck
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
            if detectionStatus?.delayed != oldValue?.delayed {
                render()
            }
            
            if let detectionStatus = detectionStatus, detectionStatus.delayed == true {
                switch detectionStatus.status {
                case .detecting:
                    checkDelayedView.detectionRunning = true
                default:
                    checkDelayedView.detectionRunning = false
                }
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
        self.removeAllSubviews()
        
        if case .exposed = exposureStatus {
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
                                             titleFont: .heading3,
                                             descriptionText: HasExposureText.ContactCardText.localized,
                                             buttonTitle: HasExposureText.ContactButtonTitle.localized,
                                             bottomText: nil,
                                             buttonTapped: { [unowned self] in self.delegate?.makeContact() })
        top = appendView(contactView, spacing: 20, top: top)
        
        if case .exposed(let notificationCount) = exposureStatus {
            
        }

        let instructionsTitle = UILabel(label: HasExposureText.InstructionsTitle.localized, font: .heading3, color: UIColor.Greyscale.black)
        instructionsTitle.numberOfLines = 0
        top = appendView(instructionsTitle, spacing: 30, top: top)
        
        let instructionsLede = UILabel(label: HasExposureText.InstructionsLede.localized, font: .bodySmall, color: UIColor.Greyscale.black)
        instructionsLede.numberOfLines = 0
        top = appendView(instructionsLede, spacing: 18, top: top)

        func bulletItem(_ text: HasExposureText) -> BulletListParagraph {
            return BulletListParagraph(content: text.localized, textColor: UIColor.Greyscale.black)
        }

        let bulletList = [
            .InstructionsSymptoms,
            .InstructionsDistancing,
            .InstructionsHygiene,
            .InstructionsAvoidTravel,
            .InstructionsShopping,
            .InstructionsCoughing,
            .InstructionsRemoteWork,
        ].map { bulletItem($0) }.asMutableAttributedString().toLabel()

        top = appendView(bulletList, spacing: 18, top: top)
         
        bulletList.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualToSuperview()
        }

        self.snp.makeConstraints { make in
            make.bottom.equalTo(bulletList)
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
        
        if detectionStatus?.delayed == true {
            top = appendView(checkDelayedView, spacing: 30, top: top)
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
            $0.detectionStatus = .init(status: .detecting, delayed: true)
        }, width: 375, height: 300)

        createPreviewInContainer(for: createView {
            $0.exposureStatus = .exposed(notificationCount: nil)
        }, width: 375, height: 1000)

        createPreviewInContainer(for: createView {
            $0.exposureStatus = .exposed(notificationCount: 10)
        }, width: 375, height: 1000)
    }
}

#endif

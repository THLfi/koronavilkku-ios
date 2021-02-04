import SnapKit
import UIKit

class NoExposuresView : ExposuresView, LocalizedView {
    enum Text : String, Localizable {
        case Heading
        case Subtitle
        case DisclaimerText
    }
    
    var timeFromLastCheck: TimeInterval? {
        didSet {
            guard let timeFromLastCheck = timeFromLastCheck, timeFromLastCheck != oldValue else { return }
            
            lastCheckedView?.timeFromLastCheck = timeFromLastCheck
        }
    }
        
    var detectionStatus: DetectionStatus? {
        didSet {
            if detectionStatus?.manualCheckAllowed() != oldValue?.manualCheckAllowed() {
                render()
            }
            
           if let detectionStatus = detectionStatus {
                checkDelayedView?.detectionRunning = detectionStatus.running
            }
        }
    }

    var lastCheckedView: ExposuresLastCheckedView!
    var checkDelayedView: CheckDelayedView?
    
    func render() {
        removeAllSubviews()
        
        layout { append in
            let header = label(text: .Heading)
            header.font = .heading2
            header.textColor = UIColor.Greyscale.black
            header.numberOfLines = 0
            append(header, UIEdgeInsets(top: 10))
            
            lastCheckedView = ExposuresLastCheckedView(value: timeFromLastCheck)
            append(lastCheckedView, UIEdgeInsets(top: 10))
            
            if detectionStatus?.delayed == true {
                checkDelayedView = CheckDelayedView() { [unowned self] in
                    self.delegate?.startManualCheck()
                }

                append(checkDelayedView!, UIEdgeInsets(top: 30))
            }

            let subtitle = label(text: .Subtitle)
            subtitle.font = .heading4
            subtitle.textColor = UIColor.Greyscale.black
            subtitle.numberOfLines = 0
            append(subtitle, UIEdgeInsets(top: 30))

            let disclaimer = label(text: .DisclaimerText)
            disclaimer.font = .bodySmall
            disclaimer.textColor = UIColor.Greyscale.black
            disclaimer.numberOfLines = 0
            append(disclaimer, UIEdgeInsets(top: 10))

            let howItWorksLink = InternalLinkLabel(
                label: Translation.HowItWorksButton.localized,
                font: UIFont.labelSecondary,
                color: UIColor.Primary.blue,
                linkTapped: { [unowned self] in
                    self.delegate?.showHowItWorks()
                },
                underline: false)

            append(howItWorksLink, UIEdgeInsets(top: 8))
        }
    }
}

#if DEBUG

import SwiftUI

struct NoExposuresView_Preview: PreviewProvider {
        static func createView(customize: (NoExposuresView) -> Void) -> NoExposuresView {
            let view = NoExposuresView()
            customize(view)
            return view
        }

    static var previews: some View = Group {
        createPreviewInContainer(for: createView {
            $0.detectionStatus = .init(status: .on, delayed: false, running: false)
        }, width: 375, height: 300)

        createPreviewInContainer(for: createView {
            $0.detectionStatus = .init(status: .on, delayed: true, running: true)
        }, width: 375, height: 500)

        createPreviewInContainer(for: createView {
            $0.detectionStatus = .init(status: .on, delayed: true, running: false)
        }, width: 375, height: 500)
    }
}

#endif

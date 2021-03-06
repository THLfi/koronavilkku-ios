import Combine
import SnapKit
import UIKit

protocol ExposuresElementDelegate : AnyObject {
    func runManualDetection()
    func showExposureGuide()
}

final class ExposuresElement: WideRowElement, LocalizedView {
    final class AccessibilityElement : UIAccessibilityElement {
        weak var exposuresElement: ExposuresElement?
        
        /// Internal storage, use `accessibilityValue` instead
        private var _accessibilityValue: String?
        
        /// Provide a default value that can be change over time without the UI being notified of the change
        /// To override this behaviour, set this property explicitly to non-nil value
        override var accessibilityValue: String? {
            get {
                if let value = _accessibilityValue {
                    return value
                }
                
                if exposuresElement?.detectionStatus?.manualCheckAllowed() == true {
                    return Text.AccessibilityValueCheckDelayed.localized
                }
                
                return exposuresElement?.lastCheckedView?.accessibilityLabel
            }
            set {
                _accessibilityValue = newValue
            }
        }

        init(parent: ExposuresElement) {
            exposuresElement = parent
            super.init(accessibilityContainer: parent)
        }
    }

    enum Text : String, Localizable {
        case TitleNoExposures
        case BodyExposureCheckDelayed
        case AccessibilityValueCheckDelayed
        case TitleHasExposures
        case BodyHasExposures
        case ButtonOpen
        case ButtonCheckNow
        case ButtonExposureGuide
    }
    
    private lazy var accessibilityElement = AccessibilityElement(parent: self)
    private var manualCheckButton: RoundedButton?
    private var lastCheckedView: ExposuresLastCheckedView?
    private var guideButton: UIButton?
    
    weak var delegate: ExposuresElementDelegate?
    
    private let margin = UIEdgeInsets(top: 24, left: 20, bottom: 20, right: -20)
    
    var timeFromLastUpdate: TimeInterval? {
        didSet {
            guard timeFromLastUpdate != oldValue else { return }
            lastCheckedView?.timeFromLastCheck = timeFromLastUpdate
        }
    }
    
    /// The current exposure status.
    ///
    /// Re-renders the entire view if the value changes.
    var exposureStatus: ExposureStatus? {
        didSet {
            guard exposureStatus != oldValue else { return }
            render()
        }
    }
    
    /// The current detection status.
    ///
    /// Has more fine-grained control over re-rendering: Changes to the button loading state are rendered without recreating the UI
    var detectionStatus: DetectionStatus? {
        didSet {
            // prevent null & same values causing re-renders
            guard let detectionStatus = detectionStatus, detectionStatus != oldValue else { return }
            
            // first value must render
            guard let oldValue = oldValue else { return render() }
            
            // exposed users see only static content
            guard case .unexposed = exposureStatus else { return }
            
            if detectionStatus.manualCheckAllowed() {
                if detectionStatus.running {
                    // only affects the button rendering
                    self.manualCheckButton?.isLoading = true
                    accessibilityElement.accessibilityValue = self.manualCheckButton?.accessibilityLabel
                } else if oldValue.running == true {
                    // reset the button state on failure
                    self.manualCheckButton?.isLoading = false
                    accessibilityElement.accessibilityValue = nil
                } else {
                    render()
                }
            } else {
                render()
            }
        }
    }
    
    /// Whether the UI has been initialized or not
    private var initialized = false
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if let guideButton = guideButton {
            accessibilityElement.accessibilityFrameInContainerSpace = bounds.divided(atDistance: guideButton.frame.minY, from: .minYEdge).slice
        } else {
            accessibilityElement.accessibilityFrameInContainerSpace = bounds
        }
    }
    
    private func createImageView() -> UIView? {
        if case .exposed = exposureStatus {
            return nil
        }
        
        if detectionStatus!.delayed || !detectionStatus!.enabled() {
            return createImageView(imageNamed: "flat-color-icons_alert", addShadow: false)
        }
        
        return createImageView(imageNamed: "flat-color-icons_ok")
    }
    
    private func createTitleLabel() -> UILabel {
        if case .exposed = exposureStatus {
            let title = createTitleLabel(title: Text.TitleHasExposures.localized)
            title.textColor = UIColor.Primary.red
            return title
        }
        
        return createTitleLabel(title: Text.TitleNoExposures.localized)
    }
    
    private func createBodyLabel() -> UILabel? {
        var body: Text
        
        switch exposureStatus! {
        case .exposed:
            body = .BodyHasExposures
            
        case .unexposed:
            guard detectionStatus!.enabled() && detectionStatus!.delayed else {
                return nil
            }
            
            body = .BodyExposureCheckDelayed
        }
        
        return createBodyLabel(body: body.localized)
    }
    
    private func createGuideButton(topAnchor: ConstraintItem) -> UIButton {
        let divider = UIView.createDivider()
        
        addSubview(divider)
        
        divider.snp.makeConstraints { make in
            make.top.equalTo(topAnchor).offset(20)
            make.left.right.equalToSuperview()
        }
        
        let button = FooterItem(title: text(key: .ButtonExposureGuide),
                                padding: UIEdgeInsets(20)) { [unowned self] in
            self.delegate?.showExposureGuide()
        }
        
        addSubview(button)
        
        button.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.left.right.equalToSuperview()
        }
        
        return button
    }
    
    func render() {
        guard let exposureStatus = self.exposureStatus,
              let detectionStatus = self.detectionStatus else { return }
        
        // reset initial state
        self.manualCheckButton = nil
        self.lastCheckedView = nil
        self.guideButton = nil
        self.accessibilityElement.accessibilityValue = nil
        
        if initialized {
            removeAllSubviews()
        }
        
        let container = UIView()
        let imageView = createImageView()
        let titleView = createTitleLabel()
        let bodyView = createBodyLabel()
        
        var bottomAnchor = container.snp.bottom
        var bottomOffset = margin.bottom
        var actionButton: RoundedButton? = nil
        
        self.addSubview(container)
        
        if let imageView = imageView {
            self.addSubview(imageView)
        }
        
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        container.addSubview(titleView)
        
        titleView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().priority(.low)
        }
        
        if case .exposed(let notificationCount) = exposureStatus {
            let exposureCountLabel = Badge(label: notificationCount?.description ?? "!", backgroundColor: UIColor.Primary.red)
            exposureCountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            container.addSubview(exposureCountLabel)
            
            exposureCountLabel.snp.makeConstraints { make in
                make.left.equalTo(titleView.snp.right).offset(10)
                make.right.lessThanOrEqualToSuperview()
            }
            
            exposureCountLabel.label.snp.makeConstraints { make in
                make.firstBaseline.equalTo(titleView)
            }
            
            actionButton = RoundedButton(title: Text.ButtonOpen.localized,
                                   backgroundColor: UIColor.Primary.red,
                                   highlightedBackgroundColor: UIColor.Primary.red,
                                   action: tapped)
        } else {
            if detectionStatus.manualCheckAllowed() {
                manualCheckButton = RoundedButton(title: Text.ButtonCheckNow.localized,
                                                  backgroundColor: UIColor.Primary.blue,
                                                  highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground) { [unowned self] in
                    self.delegate?.runManualDetection()
                }
            } else if detectionStatus.enabled() {
                self.guideButton = createGuideButton(topAnchor: container.snp.bottom)
                bottomAnchor = self.guideButton!.snp.bottom
                bottomOffset = 0
            }
            
            lastCheckedView = ExposuresLastCheckedView(style: .subdued, value: timeFromLastUpdate)
            container.addSubview(lastCheckedView!)
        }
        
        if let button = actionButton ?? manualCheckButton {
            self.addSubview(button)
            bottomAnchor = button.snp.bottom
            button.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(margin.right)
                make.left.equalToSuperview().offset(margin.left)
                make.top.equalTo(container.snp.bottom).offset(20)
            }
        }
        
        if let bodyView = bodyView {
            container.addSubview(bodyView)
            
            bodyView.snp.makeConstraints { make in
                make.top.equalTo(titleView.snp.bottom).offset(10)
                make.left.right.equalToSuperview()
            }
        }
        
        lastCheckedView?.snp.makeConstraints { make in
            make.top.equalTo((bodyView ?? titleView).snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(margin.top)
            make.left.equalToSuperview().offset(margin.left)
            
            if let imageView = imageView {
                make.right.equalTo(imageView.snp.left).offset(-20)
            } else {
                make.right.equalToSuperview().offset(margin.right)
            }
            
            make.bottom.equalTo(lastCheckedView ?? bodyView ?? titleView)
        }
        
        imageView?.snp.makeConstraints { make in
            make.top.equalTo(container).offset(bodyView != nil ? 6 : 0)
            make.right.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(bottomAnchor).offset(bottomOffset)
        }
        
        accessibilityElement.accessibilityTraits = .button
        accessibilityElement.accessibilityCustomActions = nil
        accessibilityElements = [accessibilityElement, guideButton].compactMap { $0 }

        if case .exposed = exposureStatus {
            accessibilityElement.accessibilityHint = Text.ButtonOpen.localized
            accessibilityElement.accessibilityLabel = "\(titleView.text ?? ""). \(bodyView?.text ?? "")"
        } else {
            accessibilityElement.accessibilityHint = nil
            accessibilityElement.accessibilityLabel = titleView.text
            
            if let manualCheckButton = self.manualCheckButton {
                accessibilityElement.accessibilityCustomActions = [
                    UIAccessibilityCustomAction(name: Text.ButtonCheckNow.localized) { _ in
                        return manualCheckButton.performAction()
                    }
                ]
            }
        }
        
        // let the user know we've changed the view contents
        if initialized {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
        
        initialized = true
    }
}

#if DEBUG

import SwiftUI

struct ExposuresElement_NoExposures: PreviewProvider {
    static func createView(exposureStatus: ExposureStatus,
                           detectionStatus: DetectionStatus,
                           timeFromLastUpdate: TimeInterval? = nil) -> ExposuresElement {
        
        let view = ExposuresElement()
        view.exposureStatus = exposureStatus
        view.detectionStatus = detectionStatus
        view.timeFromLastUpdate = timeFromLastUpdate
        return view
    }
    
    static var previews: some View = Group {
        createPreviewInContainer(for: createView(exposureStatus: .unexposed,
                                                 detectionStatus: .init(status: .on, delayed: false, running: false)),
                                 width: 375,
                                 height: 200)
        
        createPreviewInContainer(for: createView(exposureStatus: .unexposed,
                                                 detectionStatus: .init(status: .on, delayed: true, running: false),
                                                 timeFromLastUpdate: -1_000_000),
                                 width: 375,
                                 height: 300)
        
        createPreviewInContainer(for: createView(exposureStatus: .exposed(notificationCount: 3),
                                                 detectionStatus: .init(status: .off, delayed: true, running: false),
                                                 timeFromLastUpdate: -10_000),
                                 width: 375,
                                 height: 220)
        
        createPreviewInContainer(for: createView(exposureStatus: .exposed(notificationCount: nil),
                                                 detectionStatus: .init(status: .on, delayed: false, running: false),
                                                 timeFromLastUpdate: -1000),
                                 width: 375,
                                 height: 220)
        
        createPreviewInContainer(for: createView(exposureStatus: .unexposed,
                                                 detectionStatus: .init(status: .apiDisabled, delayed: true, running: false),
                                                 timeFromLastUpdate: -100),
                                 width: 375,
                                 height: 150)
    }
}

#endif

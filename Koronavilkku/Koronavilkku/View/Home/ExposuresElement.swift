import Combine
import UIKit

final class ExposuresElement: WideRowElement {
    enum Text : String, Localizable {
        case TitleNoExposures
        case BodyNoExposures
        case BodyExposureCheckDelayed
        case AccessibilityValueCheckDelayed
        case TitleHasExposures
        case BodyHasExposures
        case ButtonOpen
        case ButtonCheckNow
    }
    
    private var manualCheckButton: RoundedButton?
    private var lastCheckedView: ExposuresLastCheckedView?
    
    private let manualCheckAction: () -> ()
    private let margin = UIEdgeInsets(top: 24, left: 20, bottom: -20, right: -20)
    
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
                    self.accessibilityValue = self.manualCheckButton?.accessibilityLabel
                } else if oldValue.running == true {
                    // reset the button state on failure
                    self.accessibilityValue = nil
                    self.manualCheckButton?.isLoading = false
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
    
    /// Internal storage, use `accessibilityValue` instead
    private var _accessibilityValue: String?
    
    /// Provide a default value that can be change over time without the UI being notified of the change
    /// To override this behaviour, set this property explicitly to non-nil value
    override var accessibilityValue: String? {
        get {
            if let value = _accessibilityValue {
                return value
            }
            
            if detectionStatus?.delayed == true {
                return Text.AccessibilityValueCheckDelayed.localized
            }
            
            return lastCheckedView?.accessibilityLabel
        }
        set {
            _accessibilityValue = newValue
        }
    }

    private func updateProperty<T: Equatable>(keyPath: ReferenceWritableKeyPath<ExposuresElement, T>, value: T) {
        if self[keyPath: keyPath] != value {
            self[keyPath: keyPath] = value
            self.render()
        }
    }
    
    init(tapped: @escaping () -> (), manualCheckAction: @escaping () -> ()) {
        self.manualCheckAction = manualCheckAction
        super.init(tapped: tapped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            guard detectionStatus!.enabled() else {
                return nil
            }

            body = detectionStatus!.delayed ? .BodyExposureCheckDelayed : .BodyNoExposures
        }
            
        return createBodyLabel(body: body.localized)
    }
    
    func render() {
        guard let exposureStatus = self.exposureStatus,
              let detectionStatus = self.detectionStatus else { return }
        
        Log.d("ExposuresElement render()")

        // reset initial state
        self.manualCheckButton = nil
        self.lastCheckedView = nil
        
        if initialized {
            removeAllSubviews()
        }

        let container = UIView()
        let imageView = createImageView()
        let titleView = createTitleLabel()
        let bodyView = createBodyLabel()
        var button: RoundedButton? = nil
        
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
            
            button = RoundedButton(title: Text.ButtonOpen.localized,
                                   backgroundColor: UIColor.Primary.red,
                                   highlightedBackgroundColor: UIColor.Primary.red,
                                   action: tapped)
        } else {
            if detectionStatus.manualCheckAllowed() {
                manualCheckButton = RoundedButton(title: Text.ButtonCheckNow.localized,
                                                  backgroundColor: UIColor.Primary.blue,
                                                  highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground,
                                                  action: manualCheckAction)
            }
            
            lastCheckedView = ExposuresLastCheckedView(style: .subdued, value: timeFromLastUpdate)
            container.addSubview(lastCheckedView!)
        }
        
        if let button = button ?? manualCheckButton {
            self.addSubview(button)
            button.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(margin.bottom)
                make.right.equalToSuperview().offset(margin.right)
                make.left.equalToSuperview().offset(margin.left)
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
            
            if let button = button ?? manualCheckButton {
                make.bottom.equalTo(button.snp.top).offset(-20)
            } else {
                make.bottom.equalToSuperview().offset(margin.bottom)
            }
        }

        imageView?.snp.makeConstraints { make in
            make.top.equalTo(container).offset(bodyView != nil ? 6 : 0)
            make.right.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityCustomActions = nil

        if case .exposed = exposureStatus {
            accessibilityHint = Text.ButtonOpen.localized
            accessibilityLabel = "\(titleView.text ?? ""). \(bodyView?.text ?? "")"
        } else {
            accessibilityHint = nil
            accessibilityLabel = titleView.text
            
            if let manualCheckButton = self.manualCheckButton {
                accessibilityCustomActions = [
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
        
        let view = ExposuresElement(tapped: {}, manualCheckAction: {})
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

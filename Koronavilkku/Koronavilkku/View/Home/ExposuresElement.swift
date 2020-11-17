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
    private var updateTasks = Set<AnyCancellable>()
    
    /// The current exposure status
    private var exposureStatus: ExposureStatus?
    
    /// Whether the exposure checks are enabled at all
    private var checksEnabled = true

    /// Whether the checks are delayed and user is allowed to run exposure checks manually
    private var checksDelayed = false
    
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
            
            if checksDelayed {
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
            self.render(update: true)
        }
    }
    
    init(detectionStatus: AnyPublisher<DetectionStatus, Never>,
         exposureStatus: AnyPublisher<ExposureStatus, Never>,
         tapped: @escaping () -> (),
         manualCheckAction: @escaping () -> ()) {
        
        self.manualCheckAction = manualCheckAction
        super.init(tapped: tapped)
        
        // data binding
        detectionStatus
            .combineLatest(exposureStatus)
            .sink { [weak self] detectionStatus, exposureStatus in
                guard let self = self else { return }
                
                // whenever exposure status changes, we'll re-render the entire screen
                self.updateProperty(keyPath: \.exposureStatus, value: exposureStatus)
                
                // detection status has more fine grained control
                switch detectionStatus {
                case .detecting:
                    // don't re-render, just update the existing components' state
                    self.manualCheckButton?.isLoading = true
                    self.accessibilityValue = self.manualCheckButton?.accessibilityLabel

                case .disabled:
                    // different layout; causes re-render
                    self.updateProperty(keyPath: \.checksEnabled, value: false)
                
                case .idle(let delayed):
                    // either just reset the component state back to normal
                    self.accessibilityValue = nil
                    self.manualCheckButton?.isLoading = false
                    
                    // or re-render if the state has changed too much
                    if !self.checksEnabled || self.checksDelayed != delayed {
                        self.checksEnabled = true
                        self.checksDelayed = delayed
                        self.render(update: true)
                    }
                }

                // prevent unnecessary renders when setting up the screen for the first time
                if !self.initialized {
                    self.render()
                    self.initialized = true
                }
            }
            .store(in: &updateTasks)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createImageView() -> UIView? {
        if case .exposed = exposureStatus {
            return nil
        }

        if !checksEnabled || checksDelayed {
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
        
        switch exposureStatus {
        case .exposed:
            body = .BodyHasExposures
        
        case .unexposed:
            if !checksEnabled {
                return nil
            }
            
            body = checksDelayed ? .BodyExposureCheckDelayed : .BodyNoExposures
            
        case .none:
            return nil
        }
        
        return createBodyLabel(body: body.localized)
    }
    
    func render(update: Bool = false) {
        if update {
            guard initialized else { return }
            removeAllSubviews()
        }

        // reset state
        self.manualCheckButton = nil
        self.lastCheckedView = nil

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
            if checksEnabled && checksDelayed {
                manualCheckButton = RoundedButton(title: Text.ButtonCheckNow.localized,
                                                  backgroundColor: UIColor.Primary.blue,
                                                  highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground,
                                                  action: manualCheckAction)
            }
            
            lastCheckedView = ExposuresLastCheckedView(style: .subdued)
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
        
        if update {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
    }
}

#if DEBUG

import SwiftUI

struct ExposuresElement_NoExposures: PreviewProvider {
    static func createView() -> ExposuresElement {
        .init(detectionStatus: Just<DetectionStatus>(.idle(delayed: false)).eraseToAnyPublisher(),
              exposureStatus: Just<ExposureStatus>(.unexposed).eraseToAnyPublisher(),
              tapped: {},
              manualCheckAction: {})
    }

    static var previews: some View = createPreviewInContainer(for: createView(), width: 375, height: 200)
}

struct ExposuresElement_NoExposuresDelayed: PreviewProvider {
    static func createView() -> ExposuresElement {
        .init(detectionStatus: Just<DetectionStatus>(.idle(delayed: true)).eraseToAnyPublisher(),
              exposureStatus: Just<ExposureStatus>(.unexposed).eraseToAnyPublisher(),
              tapped: {},
              manualCheckAction: {})
    }

    static var previews: some View = createPreviewInContainer(for: createView(), width: 375, height: 300)
}

struct ExposuresElement_HasExposures: PreviewProvider {
    static func createView() -> ExposuresElement {
        .init(detectionStatus: Just<DetectionStatus>(.idle(delayed: false)).eraseToAnyPublisher(),
              exposureStatus: Just<ExposureStatus>(.exposed(notificationCount: 2)).eraseToAnyPublisher(),
              tapped: {},
              manualCheckAction: {})
    }

    static var previews: some View = createPreviewInContainer(for: createView(), width: 375, height: 250)
}

struct ExposuresElement_HasLegacyExposures: PreviewProvider {
    static func createView() -> ExposuresElement {
        .init(detectionStatus: Just<DetectionStatus>(.idle(delayed: false)).eraseToAnyPublisher(),
              exposureStatus: Just<ExposureStatus>(.exposed(notificationCount: nil)).eraseToAnyPublisher(),
              tapped: {},
              manualCheckAction: {})
    }

    static var previews: some View = createPreviewInContainer(for: createView(), width: 375, height: 250)
}

struct ExposuresElement_Disabled: PreviewProvider {
    static func createView() -> ExposuresElement {
        .init(detectionStatus: Just<DetectionStatus>(.disabled).eraseToAnyPublisher(),
              exposureStatus: Just<ExposureStatus>(.unexposed).eraseToAnyPublisher(),
              tapped: {},
              manualCheckAction: {})
    }

    static var previews: some View = createPreviewInContainer(for: createView(), width: 375, height: 150)
}

#endif

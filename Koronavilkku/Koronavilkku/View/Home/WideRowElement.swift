import Combine
import Foundation
import SnapKit
import UIKit

class WideRowElement: CardElement {
    
    let tapped: () -> ()

    init(tapped: @escaping () -> () = {}) {
        self.tapped = tapped
        super.init()
        initUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        self.addGestureRecognizer(tapGesture)
        createSubViews()
    }
 
    @objc func tapHandler() {
        self.tapped()
    }

    func createSubViews() {
        self.removeAllSubviews()
    }
    
    func createTitleLabel(title: String) -> UILabel {
        let titleView = UILabel(label: title, font: UIFont.heading4, color: UIColor.Greyscale.black)
        titleView.numberOfLines = 0
        return titleView
    }

    func createBodyLabel(body: String) -> UILabel {
        // TODO line height - https://stackoverflow.com/a/5513730
        let bodyLabel = UILabel(label: body, font: UIFont.labelTertiary, color: UIColor.Greyscale.black)
        bodyLabel.numberOfLines = 0
        if #available(iOS 14.0, *) {
            bodyLabel.lineBreakStrategy = .hangulWordPriority
        }
        return bodyLabel
    }
    
    func createImageView(imageNamed: String, addShadow: Bool = true) -> UIView {
        let image = UIImage(named: imageNamed)
        let imageView = UIImageView(image: image)
        
        if !addShadow {
            return imageView
        }
        
        imageView.setElevation(.elevation1)

        let wrapper = UIView()
        wrapper.setElevation(.elevation2)
        
        let shadowPath = UIBezierPath(ovalIn: imageView.bounds).cgPath
        wrapper.layer.shadowPath = shadowPath
        imageView.layer.shadowPath = shadowPath

        wrapper.addSubview(imageView)
        return wrapper
    }
}

final class ExposuresElement: WideRowElement {
    enum Text : String, Localizable {
        case TitleNoExposures
        case BodyNoExposures
        case BodyExposureCheckDelayed
        case TitleHasExposures
        case BodyHasExposures
        case ButtonOpen
        case ButtonCheckNow
    }
    
    var manualCheckButton: RoundedButton?
    let manualCheckAction: () -> ()
    let margin = UIEdgeInsets(top: 24, left: 20, bottom: -20, right: -20)
    var updateTasks = Set<AnyCancellable>()
    
    /// The number of active exposures
    var exposureCount = 0
    
    /// Whether the exposure checks are enabled at all
    var checksEnabled = true

    /// Whether the user is allowed to run exposure checks manually
    var checksDelayed = false

    private func updateProperty<T: Equatable>(keyPath: ReferenceWritableKeyPath<ExposuresElement, T>, value: T) {
        if self[keyPath: keyPath] != value {
            self[keyPath: keyPath] = value
            self.createSubViews()
        }
    }
    
    init(tapped: @escaping () -> (), manualCheckAction: @escaping () -> ()) {
        self.manualCheckAction = manualCheckAction
        super.init(tapped: tapped)
        
        LocalStore.shared.$exposures.$wrappedValue
            .sink { [weak self] exposures in
                self?.updateProperty(keyPath: \.exposureCount, value: exposures.count)
            }
            .store(in: &updateTasks)
        
        LocalStore.shared.$uiStatus.$wrappedValue
            .map { status in
                switch status {
                case .apiDisabled, .off:
                    return false
                default:
                    return true
                }
            }
            .sink { [weak self] enabled in
                self?.updateProperty(keyPath: \.checksEnabled, value: enabled)
            }
            .store(in: &updateTasks)
        
        Environment.default.exposureRepository.detectionStatus
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .disabled:
                    self.updateProperty(keyPath: \.checksEnabled, value: false)
                case .idle(let delayed):
                    self.manualCheckButton?.isLoading = false
                    
                    if !self.checksEnabled || self.checksDelayed != delayed {
                        self.checksEnabled = true
                        self.checksDelayed = delayed
                        self.createSubViews()
                    }
                case .detecting:
                    self.manualCheckButton?.isLoading = true
                }
            }
            .store(in: &updateTasks)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createImageView() -> UIView {
        if exposureCount > 0 {
            return createImageView(imageNamed: "flat-color-icons_notifications")
        }

        if !checksEnabled || checksDelayed {
            return createImageView(imageNamed: "flat-color-icons_alert", addShadow: false)
        }
        
        return createImageView(imageNamed: "flat-color-icons_ok")
    }
    
    private func createTitleLabel() -> UILabel {
        if exposureCount > 0 {
            let title = createTitleLabel(title: Text.TitleHasExposures.localized)
            title.textColor = UIColor.Primary.red
            return title
        }

        return createTitleLabel(title: Text.TitleNoExposures.localized)
    }
    
    private func createBodyLabel() -> UILabel? {
        var body: Text
        
        switch true {
        case exposureCount > 0:
            body = .BodyHasExposures
        case !checksEnabled:
            return nil
        case checksDelayed:
            body = .BodyExposureCheckDelayed
        default:
            body = .BodyNoExposures
        }
        
        return createBodyLabel(body: body.localized)
    }
    
    override func createSubViews() {
        super.createSubViews()

        // reset state
        self.isAccessibilityElement = false
        self.manualCheckButton = nil

        let container = UIView()
        let imageView = createImageView()
        let titleView = createTitleLabel()
        let bodyView = createBodyLabel()
        let accessibilityView: UIView
        var additionalView: UIView?
        var button: RoundedButton? = nil

        self.addSubview(container)
        self.addSubview(imageView)

        if exposureCount > 0 {
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
            
            additionalView = ExposuresLastCheckedView(style: .subdued)
            container.addSubview(additionalView!)
        }
        
        if let button = button ?? manualCheckButton {
            accessibilityView = container
            self.addSubview(button)
            button.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(margin.bottom)
                make.right.equalToSuperview().offset(margin.right)
                make.left.equalToSuperview().offset(margin.left)
            }
        } else {
            accessibilityView = self
        }
        
        container.addSubview(titleView)

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        if let bodyView = bodyView {
            container.addSubview(bodyView)

            bodyView.snp.makeConstraints { make in
                make.top.equalTo(titleView.snp.bottom).offset(10)
                make.left.right.equalToSuperview()
            }
        }
        
        additionalView?.snp.makeConstraints { make in
            make.top.equalTo((bodyView ?? titleView).snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(margin.top)
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalTo(imageView.snp.left).offset(-20)
            make.bottom.equalTo(additionalView ?? bodyView ?? titleView)
            
            if let button = button ?? manualCheckButton {
                make.bottom.equalTo(button.snp.top).offset(-20)
            } else {
                make.bottom.equalToSuperview().offset(margin.bottom)
            }
        }

        imageView.snp.makeConstraints { make in
            make.top.equalTo(container).offset(bodyView != nil ? 6 : 0)
            make.right.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        titleView.isAccessibilityElement = false
        bodyView?.isAccessibilityElement = false
        accessibilityView.accessibilityTraits = .button
        accessibilityView.isAccessibilityElement = true
        accessibilityView.accessibilityLabel = titleView.text
        accessibilityView.accessibilityValue = bodyView?.text
    }
}

final class SymptomsElement: WideRowElement {
    enum Text : String, Localizable {
        case Title
        case Body
    }
    
    let margin = UIEdgeInsets(top: 20, left: 20, bottom: -20, right: -20)

    override func createSubViews() {
        super.createSubViews()

        let container = UIView()
        let imageView = UIImageView(image: UIImage(named: "symptoms-cropped")!)
        let textContainer = UIView()
        let titleView = createTitleLabel(title: Text.Title.localized)
        let bodyView = createBodyLabel(body: Text.Body.localized)
        
        self.addSubview(container)
        container.addSubview(textContainer)
        container.addSubview(imageView)
        textContainer.addSubview(titleView)
        textContainer.addSubview(bodyView)
                
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        textContainer.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(margin.top)
            make.bottom.lessThanOrEqualToSuperview().offset(margin.bottom)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalTo(imageView.snp.left)
        }

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        bodyView.snp.makeConstraints{ make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.bottom.left.right.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.top.equalToSuperview().priority(.low)
            make.size.equalTo(CGSize(width: 135, height: 110))
        }
        
        container.clipsToBounds = true
        container.layer.cornerRadius = cornerRadius
        titleView.isAccessibilityElement = false
        bodyView.isAccessibilityElement = false
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = titleView.text
        self.accessibilityValue = bodyView.text
    }
}

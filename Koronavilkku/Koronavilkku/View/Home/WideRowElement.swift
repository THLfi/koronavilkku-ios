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
    
    func createImageView(image: UIImage) -> UIView {
        let wrapper = UIView()
        wrapper.setElevation(.elevation2)

        let image = UIImageView(image: image)
        image.setElevation(.elevation1)
        
        let shadowPath = UIBezierPath(ovalIn: image.bounds).cgPath
        wrapper.layer.shadowPath = shadowPath
        image.layer.shadowPath = shadowPath

        wrapper.addSubview(image)
        return wrapper
    }
}

final class ExposuresElement: WideRowElement {
    enum Text : String, Localizable {
        case TitleNoExposures
        case BodyNoExposures
        case TitleHasExposures
        case BodyHasExposures
        case ButtonOpen
        case ButtonCheckNow
    }
    
    let manualCheckAction: () -> ()
    let margin = UIEdgeInsets(top: 24, left: 20, bottom: -20, right: -20)
    var updateTasks = Set<AnyCancellable>()
    var exposureCount: Int = 0
    var allowManualCheck = false
    var manualCheckButton: RoundedButton?
    
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
        
        Environment.default.exposureRepository.manualDetectionStatus
            .sink { [weak self] state in
                switch state {
                case .idle(let allow):
                    self?.manualCheckButton?.isLoading = false
                    self?.updateProperty(keyPath: \.allowManualCheck, value: allow)
                case .detecting:
                    self?.manualCheckButton?.isLoading = true
                }
            }
            .store(in: &updateTasks)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func createSubViews() {
        super.createSubViews()

        let imageName: String
        let title, body: Text
        var button: RoundedButton? = nil
        manualCheckButton = nil
        
        if exposureCount == 0 {
            imageName = "flat-color-icons_ok"
            title = .TitleNoExposures
            body = .BodyNoExposures
        } else {
            imageName = "flat-color-icons_notifications"
            title = .TitleHasExposures
            body = .BodyHasExposures
        }

        let container = UIView()
        let imageView = createImageView(image: UIImage(named: imageName)!)
        let titleView = createTitleLabel(title: title.localized)
        let bodyView = createBodyLabel(body: body.localized)
        let accessibilityView: UIView
        var additionalView: UIView?

        self.addSubview(container)
        self.addSubview(imageView)
        container.addSubview(titleView)
        container.addSubview(bodyView)

        if exposureCount > 0 {
            accessibilityView = container
            button = RoundedButton(title: Text.ButtonOpen.localized,
                                       backgroundColor: UIColor.Primary.red,
                                       highlightedBackgroundColor: UIColor.Primary.red,
                                       action: tapped)
            titleView.textColor = UIColor.Primary.red
            button!.isHidden = false
        } else {
            if allowManualCheck {
                manualCheckButton = RoundedButton(title: Text.ButtonCheckNow.localized,
                                       backgroundColor: UIColor.Primary.blue,
                                       highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground,
                                       action: manualCheckAction)
                
                self.addSubview(manualCheckButton!)
                
                manualCheckButton!.snp.makeConstraints { make in
                    make.bottom.equalToSuperview().offset(margin.bottom)
                    make.right.equalToSuperview().offset(margin.right)
                    make.left.equalToSuperview().offset(margin.left)
                }
            }
            
            accessibilityView = self
            additionalView = ExposuresLastCheckedView(style: .subdued)
            container.addSubview(additionalView!)
        }
        
        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        bodyView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        
        additionalView?.snp.makeConstraints { make in
            make.top.equalTo(bodyView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(margin.top)
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalTo(imageView.snp.left).offset(-20)
            make.bottom.equalTo(additionalView ?? bodyView)
            
            if let button = button ?? manualCheckButton {
                make.bottom.equalTo(button.snp.top).offset(-20)
            } else {
                make.bottom.equalToSuperview().offset(margin.bottom)
            }
        }

        imageView.snp.makeConstraints { make in
            make.top.equalTo(container).offset(6)
            make.right.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        self.isAccessibilityElement = false // In case button visibility changes.
        titleView.isAccessibilityElement = false
        bodyView.isAccessibilityElement = false
        accessibilityView.accessibilityTraits = .button
        accessibilityView.isAccessibilityElement = true
        accessibilityView.accessibilityLabel = title.localized
        accessibilityView.accessibilityValue = body.localized
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

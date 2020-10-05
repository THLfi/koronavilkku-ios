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
        let shadowOffset = CGSize(width: 0, height: 4)

        let wrapper = UIView()
        wrapper.layer.shadowColor = .dropShadow
        wrapper.layer.shadowOffset = shadowOffset
        wrapper.layer.shadowOpacity = 0.2
        wrapper.layer.shadowRadius = 20

        let image = UIImageView(image: image)
        image.layer.shadowColor = .dropShadow
        image.layer.shadowOffset = shadowOffset
        image.layer.shadowOpacity = 0.1
        image.layer.shadowRadius = 14
        
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
    }
    
    let margin = UIEdgeInsets(top: 24, left: 20, bottom: -20, right: -20)
    var updateTask: AnyCancellable?
    var counter: Int = 0
    
    override init(tapped: @escaping () -> () = {}) {
        super.init(tapped: tapped)
        
        updateTask = LocalStore.shared.$exposures.$wrappedValue.sink(receiveValue: { [weak self] exposures in
            self?.counter = exposures.count
            self?.createSubViews()
        })
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func createSubViews() {
        super.createSubViews()

        let imageName: String
        let title, body: Text
        
        if counter == 0 {
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
        let button = RoundedButton(title: Text.ButtonOpen.localized,
                                   backgroundColor: UIColor.Primary.red,
                                   highlightedBackgroundColor: UIColor.Primary.red,
                                   action: tapped)

        if counter > 0 {
            titleView.textColor = UIColor.Primary.red
            button.isHidden = false
        } else {
            button.isHidden = true
        }
        
        self.addSubview(container)
        container.addSubview(titleView)
        container.addSubview(bodyView)
        self.addSubview(imageView)
        self.addSubview(button)

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        bodyView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.bottom.left.right.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(margin.top)
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalTo(imageView.snp.left).offset(-20)
            
            if button.isHidden {
                make.bottom.equalToSuperview().offset(margin.bottom)
            } else {
                make.bottom.equalTo(button.snp.top).offset(-20)
            }
        }

        imageView.snp.makeConstraints { make in
            make.top.equalTo(container).offset(6)
            make.right.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        self.isAccessibilityElement = false // In case button visibility changes.
        let accessibilityView: UIView
        
        if !button.isHidden {
            button.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(margin.bottom)
                make.right.equalToSuperview().offset(margin.right)
                make.left.equalToSuperview().offset(margin.left)
            }
            accessibilityView = container
            
        } else {
            accessibilityView = self
        }

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

        let imageView = UIImageView(image: UIImage(named: "symptoms-cropped")!)
        let container = UIView()
        let titleView = createTitleLabel(title: Text.Title.localized)
        let bodyView = createBodyLabel(body: Text.Body.localized)
        
        self.addSubview(container)
        self.addSubview(imageView)
        container.addSubview(titleView)
        container.addSubview(bodyView)
        
        container.snp.makeConstraints { make in
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
            // TODO would look nicer with larger fonts (and big screen) if available height would be utilized -> but it also decreases text area width -> image width needs to restricted, e.g. max 75% of parent area width + image shouldn't have that much empty space on the left.
        }
        
        titleView.isAccessibilityElement = false
        bodyView.isAccessibilityElement = false
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = titleView.text
        self.accessibilityValue = bodyView.text
    }
}

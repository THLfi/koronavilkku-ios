import Combine
import ExposureNotification
import Foundation
import SnapKit
import UIKit

enum RadarStatus: Int, Codable {
    case on
    case off
    case locked
    case btOff
    case apiDisabled
}

extension RadarStatus {
    init(from status: ENStatus) {
        switch status {
        case .active:
            self = .on
        case .bluetoothOff:
            self = .btOff
        case .disabled:
            self = .off
        default:
            self = .apiDisabled
        }
    }
}

final class RadarAnimation : UIImageView {
    init() {
        super.init(image: UIImage(named: "radar-background"))
        render()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func render() {
        contentMode = .scaleAspectFit
        
        let animated = UIImageView(image: UIImage(named: "radar-animated"))
        addSubview(animated)
        
        animated.snp.makeConstraints { make in
            make.centerX.width.equalToSuperview()
            make.height.equalTo(animated.snp.width)
            make.top.equalToSuperview()
        }
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Double.pi * 2
        rotationAnimation.duration = 9.0
        rotationAnimation.repeatCount = .infinity
        animated.layer.add(rotationAnimation, forKey: nil)
        
        let foreground = UIImageView(image: UIImage(named: "radar-foreground"))
        addSubview(foreground)
        
        foreground.snp.makeConstraints { make in
            make.center.width.height.equalToSuperview()
        }
        
        for bar in 1...3 {
            let barImg = UIImageView(image: UIImage(named: "radar-bar-\(bar)"))
            barImg.layer.opacity = 0
            foreground.addSubview(barImg)
            barImg.snp.makeConstraints { make in
                make.center.width.height.equalToSuperview()
            }
            let fadeInOut = CAKeyframeAnimation(keyPath: "opacity")
            fadeInOut.beginTime = CACurrentMediaTime() + CFTimeInterval(bar - 1) / 4.0
            fadeInOut.keyTimes = [0, 0.25, 0.5, 0.75, 1]
            fadeInOut.values = [0.0, 0.0, 1.0, 0.0, 0.0]
            fadeInOut.autoreverses = true
            fadeInOut.duration = 2.0
            fadeInOut.repeatCount = .infinity
            barImg.layer.add(fadeInOut, forKey: nil)
        }
    }
}

final class StatusHeaderView: UIView {
    enum Text : String, Localizable {
        case TitleEnabled
        case TitleDisabled
        case TitleLocked

        case BodyEnabled
        case BodyDisabled
        case BodyLocked
        case BodyBTOff
        
        case EnableButton
    }

    var radarStatus: RadarStatus?
    var radarContainer: UIView!
    var titleLabel: UILabel!
    var bodyLabel: UILabel!
    var button: UIButton!
    var buttonConstraint: Constraint!
    let exposureRepository = Environment.default.exposureRepository
    var updateTask: AnyCancellable? = nil
    var openSettingsHandler: ((_ type: OpenSettingsType) -> Void)? = nil
    
    let verticalPadding = CGFloat(30)
    let imageHeight = CGFloat(138)
    let imageWidth = CGFloat(118)
    
    init() {
        super.init(frame: .zero)

        createUI()

        updateTask = LocalStore.shared.$uiStatus.$wrappedValue.sink { [weak self] status in
            guard let self = self else {
                return
            }
            
            UIView.defaultTransition(with: self) {
                self.radarStatus = status
                self.render()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Adjust the status header size by increasing the radar height and top spacing.
     
     This method is called from the scroll view delegate for a visual effect where the element seems to stay in place and stretch vertically as the user drags over the edge.
     
     - Parameters:
        - by: the (negative) offset the user has dragged over the top edge
        - topInset: the amount of safe area inset the previous value contains
     */
    func adjustSize(by totalOffset: CGFloat, topInset: CGFloat) {
        // we're splitting the extra space in the half: 50% for the image, 50% to spacing
        let extraSpace = (0 - totalOffset - topInset) / 2
        
        self.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(totalOffset < 0 ? totalOffset : 0)
        }
        
        let paddingTop = verticalPadding + topInset

        radarContainer.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(extraSpace > 0 ? paddingTop + extraSpace : paddingTop)
            make.height.equalTo(extraSpace > 0 ? imageHeight + extraSpace : imageHeight)
        }
    }
    
    func render() {
        renderRadar()
        titleLabel.text = getTitleText().localized
        titleLabel.textColor = getTitleFontColor()
        bodyLabel.text = getBodyText().localized
        
        if let buttonTitle = getButtonTitle() {
            button.isHidden = false
            button.setTitle(buttonTitle.localized, for: .normal)
            buttonConstraint.activate()
        } else {
            button.isHidden = true
            buttonConstraint.deactivate()
        }
    }
    
    private func renderRadar() {
        radarContainer.removeAllSubviews()
        let radarView = getRadarView()
        radarContainer.addSubview(radarView)
        radarView.snp.makeConstraints { make in
            make.top.height.centerX.equalToSuperview()
            make.width.equalTo(radarView.snp.height).multipliedBy(imageWidth / imageHeight)
        }
    }
    
    private func createUI() {
        backgroundColor = UIColor.Greyscale.white
        
        radarContainer = UIView()
        self.addSubview(radarContainer)
        radarContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(verticalPadding)
            make.left.right.equalToSuperview()
            make.height.equalTo(imageHeight)
        }
        
        let container = UIView()
        self.addSubview(container)
        
        container.snp.makeConstraints { make in
            make.top.equalTo(radarContainer.snp.bottom)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(30)
        }
        
        titleLabel = UILabel(label: getTitleText().localized,
                             font: UIFont.heading3,
                             color: getTitleFontColor())
        
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = -1
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        bodyLabel = UILabel(label: getBodyText().localized,
                            font: UIFont.labelTertiary,
                            color: UIColor.Greyscale.black)
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        container.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.medium)
        }
        
        button = RoundedButton(title: "",
                               backgroundColor: UIColor.Primary.red,
                               highlightedBackgroundColor: UIColor.Primary.red) { [unowned self] in
            self.buttonAction()
        }
        container.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.top.equalTo(bodyLabel.snp.bottom).offset(20)
            buttonConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    private func buttonAction() {
        switch radarStatus {
        case .btOff:
            openSettings(.bluetooth)

        case .apiDisabled:
            // attempt to enable the disabled API first
            // in some cases the system pops up a dialog where the user is able to
            // activate the API, eg. after being completely turned off (in iOS 13.7+)
            // or when another app is currently active (prior to iOS 13.7)
            exposureRepository.tryEnable { [weak self] errorCode in
                // API activated
                guard let code = errorCode else {
                    return
                }
                
                // iOS 13.7+ we can no longer reliably determine anything from the error code;
                // just show instructions how to enable the API in Settings.app
                if #available(iOS 13.7, *) {
                    self?.openSettings(.exposureNotifications)
                } else {
                    // in iOS prior to 13.7, attempting to enable the API results in .notAuthorized
                    // when the API has been disabled and .restricted when the user rejects the
                    // presented dialog; avoid showing instructions if the user rejected
                    if code != .restricted {
                        self?.openSettings(.exposureNotifications)
                    }
                }
            }

        case .off:
            exposureRepository.setStatus(enabled: true)

        default:
            break
        }
    }
    
    private func openSettings(_ type: OpenSettingsType) {
        guard let handler = self.openSettingsHandler else { return }
        handler(type)
    }
    
    private func getRadarView() -> UIImageView {
        switch(radarStatus) {
        case .on:
            return RadarAnimation()
        case .off, .locked, .apiDisabled, .btOff, .none:
            let imageView = UIImageView(image: UIImage(named: "radar-off"))
            imageView.contentMode = .scaleAspectFit
            return imageView
        }
    }
    
    private func getTitleText() -> Text {
        switch(radarStatus) {
        case .on:
            return .TitleEnabled
        case .off, .apiDisabled, .btOff, .none:
            return .TitleDisabled
        case .locked:
            return .TitleLocked
        }
    }
    
    private func getBodyText() -> Text {
        switch(radarStatus) {
        case .on:
            return .BodyEnabled
        case .off, .apiDisabled, .none:
            return .BodyDisabled
        case .locked:
            return .BodyLocked
        case .btOff:
            return .BodyBTOff
        }
    }
    
    private func getTitleFontColor() -> UIColor {
        switch(radarStatus) {
        case .on:
            return UIColor.Primary.blue
        case .off, .apiDisabled, .btOff, .none:
            return UIColor.Primary.red
        case .locked:
            return UIColor.Greyscale.darkGrey
        }
    }
    
    private func getButtonTitle() -> Text? {
        switch radarStatus {
        case .on, .locked, .none:
            return nil
        case .apiDisabled, .btOff, .off:
            return .EnableButton
        }
    }
}

#if DEBUG
import SwiftUI

struct CollapsibleHeaderViewPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: StatusHeaderView(),
        width: 375,
        height: 339
    )
}
#endif

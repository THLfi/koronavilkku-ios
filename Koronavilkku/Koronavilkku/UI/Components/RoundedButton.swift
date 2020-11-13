import Combine
import Foundation
import UIKit

class RoundedButton: UIButton {

    override var buttonType: UIButton.ButtonType {
        .system
    }
    
    override open var isHighlighted: Bool {
        didSet {
            if !isLoading {
                backgroundColor = isHighlighted ? highlightedBackgroundColor : enabledBackgroundColor
            }

            layer.shadowColor = isHighlighted ? UIColor.clear.cgColor : UIColor.Greyscale.lightGrey.cgColor
        }
    }
    
    var isLoading = false {
        didSet {
            guard oldValue != isLoading else { return }
            
            if isLoading {
                backgroundColor = UIColor.Greyscale.backdropGrey
                setImage(UIImage.init(named: "refresh")?.withTintColor(UIColor.Greyscale.mediumGrey), for: .normal)
                setTitle(nil, for: .normal)
                accessibilityLabel = Translation.ButtonLoading.localized
                runLoadingAnimation()
            } else {
                backgroundColor = isEnabled ? enabledBackgroundColor : disabledBackgroundColor
                imageView?.layer.removeAllAnimations()
                setImage(nil, for: .normal)
                setTitle(title, for: .normal)
                accessibilityLabel = nil
            }
        }
    }
    
    static let height: CGFloat = 50
    
    let title: String
    let action: () -> ()
    
    private let disabledBackgroundColor = UIColor.Greyscale.lightGrey
    private let enabledBackgroundColor: UIColor
    private let highlightedBackgroundColor: UIColor
    
    private var restartAnimationTask: AnyCancellable?

    init(title: String,
         disabledTitle: String? = nil,
         backgroundColor: UIColor = UIColor.Primary.blue,
         highlightedBackgroundColor: UIColor = UIColor.Secondary.buttonHighlightedBackground,
         action: @escaping () -> ()) {
        
        self.title = title
        self.action = action
        self.enabledBackgroundColor = backgroundColor
        self.highlightedBackgroundColor = highlightedBackgroundColor
        
        super.init(frame: .zero)
            
        self.setTitle(title, for: .normal)
        self.setTitleColor(UIColor.Greyscale.white, for: .normal)
        self.backgroundColor = backgroundColor
        self.titleLabel?.font = UIFont.labelPrimary
        
        self.layer.cornerRadius = 25
        self.setElevation(.elevation1)
        self.addTarget(self, action: #selector(performAction), for: .touchUpInside)
        
        self.snp.makeConstraints { make in
            make.height.equalTo(RoundedButton.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
    
    @objc func performAction() -> Bool {
        if !isLoading {
            action()
            return true
        }
        
        return false
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
        backgroundColor = enabled ? enabledBackgroundColor : disabledBackgroundColor
    }
    
    private func runLoadingAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = CGFloat(Double.pi * 2.0)
        animation.duration = 2
        animation.repeatCount = .greatestFiniteMagnitude
        imageView?.layer.add(animation, forKey: nil)
        
        if restartAnimationTask == nil {
            restartAnimationTask = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                .print()
                .sink { [weak self] _ in
                    guard let self = self, self.isLoading else { return }
                    self.runLoadingAnimation()
                }
        }
    }
}

import Combine
import Foundation
import SnapKit
import UIKit

class OpenSettingsViewController: UIViewController {

    let content: OpenSettingsContent
    
    // If true then display a close button.
    let userDismissable: Bool
    
    // Return true if the status is such that the OpenSettingsViewController no longer needs to be visible.
    let dismissCheck: (RadarStatus) -> Bool
    
    // Handles dismissing the view controller.
    let dismisser: () -> Void
    
    var statusUpdateTask: AnyCancellable? = nil
    
    init(content: OpenSettingsContent, userDismissable: Bool, dismissCheck: @escaping (RadarStatus) -> Bool, dismisser: @escaping () -> Void) {
        self.content = content
        self.userDismissable = userDismissable
        self.dismissCheck = dismissCheck
        self.dismisser = dismisser
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        statusUpdateTask = LocalStore.shared.$uiStatus.$wrappedValue.sink { [weak self] status in
            guard self?.dismissCheck(status) == true else {
                return
            }
            
            DispatchQueue.main.async {
                self?.dismisser()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        statusUpdateTask = nil
    }
    
    private func initUI() {
        let buttonMarginBottom: CGFloat = 60
        let buttonAreaHeight = RoundedButton.height + buttonMarginBottom + 40
        let margins = UIEdgeInsets(top: 60, left: 40, bottom: buttonAreaHeight, right: 40)
        let contentView = view.addScrollableContentView(
            backgroundColor: UIColor.Greyscale.white,
            margins: margins)
        var top = contentView.snp.top
        
        if userDismissable {
            let closeButton = UIButton(type: .close)
            closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
            view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(CGSize(width: 30, height: 30))
            }
        }

        let title = UILabel(label: content.title.localized, font: UIFont.heading1, color: UIColor.Greyscale.black)
        title.setLineHeight(0.84)
        title.numberOfLines = 0
        top = contentView.appendView(title, spacing: 60, top: top)
        
        let text = UILabel(label: content.text.localized, font: UIFont.heading4, color: UIColor.Greyscale.black)
        text.numberOfLines = 0
        top = contentView.appendView(text, spacing: 30, top: top)
        
        if let stepsText = content.steps?.localized {
            let steps = UILabel(label: stepsText, font: UIFont.bodySmall, color: UIColor.Greyscale.darkGrey)
            steps.setLineHeight(0.84)
            steps.numberOfLines = 0
            top = contentView.appendView(steps, spacing: 30, top: top)
        }

        contentView.subviews.last?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
        
        let fade = FadeBlock()
        view.addSubview(fade)
        fade.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(margins.bottom)
        }
        
        let button = RoundedButton(title: Translation.OpenSettingsButton.localized, action: { [weak self] in
            self?.openSettings()
        })
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(margins)
            make.bottom.equalTo(view.safeAreaInsets).offset(-buttonMarginBottom)
        }
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: {})
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    static func create(type: OpenSettingsType, userDismissable: Bool = true, dismisser: @escaping () -> Void) -> UIViewController {
        let content: OpenSettingsContent
        let dismissCheck: (RadarStatus) -> Bool
        
        switch type {
        case .bluetooth:
            content = OpenSettingsContent(title: Translation.BluetoothDisabledTitle,
                                          text: Translation.BluetoothDisabledText,
                                          steps: nil)
            dismissCheck = { status in status != .btOff }

        case .exposureNotifications:
            var steps = Translation.ENBlockedSteps
            
            if #available(iOS 13.7, *) {
                steps = Translation.ENBlockedStepsNew
            }
            
            content = OpenSettingsContent(title: Translation.ENBlockedTitle,
                                          text: Translation.ENBlockedText,
                                          steps: steps)
            dismissCheck = { status in status != .apiDisabled }
        }

        return OpenSettingsViewController(content: content,
                                          userDismissable: userDismissable,
                                          dismissCheck: dismissCheck,
                                          dismisser: dismisser)
    }
}

struct OpenSettingsContent {
    let title: Translation
    let text: Translation
    let steps: Translation?
}

enum OpenSettingsType {
    case bluetooth
    case exposureNotifications
}

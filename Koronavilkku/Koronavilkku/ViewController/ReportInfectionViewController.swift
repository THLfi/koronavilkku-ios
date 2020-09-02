import Foundation
import UIKit
import SnapKit

class ReportInfectionViewController: UIViewController {
    enum Text : String, Localizable {
        case LockedTitle
        case LockedText
        case DisabledText
        case ReportTitle
        case ReportText
        case ReportButton
        case ReportItemPrivacy
        case ReportItemNotify
        case ReportItemGuide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()

        LocalStore.shared.$uiStatus.addObserver(using: {
            self.initUI()
        })
    }
    
    private func initUI() {
        view.removeAllSubviews()

        switch LocalStore.shared.uiStatus {
        case .locked:
            showNotice(image: UIImage(named: "ok"), title: .LockedTitle, text: .LockedText)
        case .apiDisabled:
            showNotice(image: UIImage(named: "radar-off"), text: .DisabledText)
        default:
            showInstructions()
        }
    }
    
    private func pushToPublishTokensVC() {
        self.pushToPublishTokensVC(with: nil)
    }
    
    func pushToPublishTokensVC(with code: String?) {
        guard LocalStore.shared.uiStatus != .apiDisabled else {
            Log.d("Cannot publish tokens because EN API is disabled")
            return
        }
        
        guard LocalStore.shared.uiStatus != .locked else {
            Log.d("User has already published tokens")
            return
        }

        let publishTokensVC = PublishTokensViewController()
        
        if let code = code {
            publishTokensVC.setCode(code)
        }

        let childNavController = UINavigationController(rootViewController: publishTokensVC)
        childNavController.modalPresentationStyle = .fullScreen
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.Secondary.blueBackdrop
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont.labelPrimary,
            .foregroundColor: UIColor.Greyscale.black
        ]
        
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .font: UIFont.labelPrimary,
        ]

        appearance.buttonAppearance = buttonAppearance
        
        childNavController.navigationBar.standardAppearance = appearance
        childNavController.navigationBar.tintColor = UIColor.Primary.blue
        
        self.navigationController?.present(childNavController, animated: true)
    }
    
    private func showInstructions() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = Text.ReportTitle.localized

        let margin = UIEdgeInsets(top: 20, left: 20, bottom: 30, right: 20)
        let contentView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: margin)
        
        var top = contentView.snp.top
        
        let text = UILabel(label: Text.ReportText.localized, font: .bodyLarge, color: UIColor.Greyscale.black)
        text.numberOfLines = 0
        top = contentView.appendView(text, top: top)
        
        let button = RoundedButton(title: Text.ReportButton.localized,
                                   action: self.pushToPublishTokensVC)
        top = contentView.appendView(button, spacing: 30, top: top)
        
        button.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualTo(contentView.snp.bottom)
        }

        let bulletList = [
            Text.ReportItemPrivacy,
            Text.ReportItemNotify,
            Text.ReportItemGuide,
        ]
            .map { BulletListParagraph(content: $0.localized, textColor: UIColor.Greyscale.darkGrey) }
            .asMutableAttributedString()
            .toLabel()
        top = contentView.appendView(bulletList, spacing: 30, top: top)
        
        bulletList.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func showNotice(image: UIImage?, title: Text? = nil, text: Text) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.title = nil
        
        let margin = UIEdgeInsets(top: 100, left: 20, bottom: 20, right: 20)
        let contentView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: margin)

        let image = UIImageView(image: image)
        image.contentMode = .scaleAspectFit
        contentView.addSubview(image)
        image.snp.makeConstraints { make in
            make.height.equalTo(150)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        let top: ConstraintItem

        if let title = title {
            let title = UILabel(label: title.localized, font: .heading3, color: UIColor.Greyscale.black)
            title.numberOfLines = 0
            title.textAlignment = .center
            contentView.addSubview(title)
            title.snp.makeConstraints { make in
                make.top.equalTo(image.snp.bottom).offset(30)
                make.left.right.equalToSuperview()
            }
            top = title.snp.bottom

        } else {
            top = image.snp.bottom
        }

        let body = UILabel(label: text.localized, font: .bodySmall, color: UIColor.Greyscale.black)
        body.numberOfLines = 0
        body.textAlignment = .center
        contentView.addSubview(body)
        body.snp.makeConstraints { make in
            make.top.equalTo(top).offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}


#if DEBUG
import SwiftUI

struct ReportInfectionViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: RootViewController(initialTab: .reportInfection))
}
#endif

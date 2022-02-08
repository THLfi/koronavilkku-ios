import Foundation
import UIKit
import SnapKit

class ReportInfectionViewController: UIViewController {
    enum Text : String, Localizable {
        case LockedTitle
        case LockedText
        case DisabledText
        case ReportTitle
        case ReportMessagePrimary
        case ReportMessageSecondary
        case ReportButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()

        LocalStore.shared.$uiStatus.addObserver(using: { [weak self] in
            self?.initUI()
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
    
    func startReportInfectionFlow(with code: String?) {
        switch LocalStore.shared.uiStatus {
        case .apiDisabled:
            Log.d("Cannot publish tokens because EN API is disabled")
        case .locked:
            Log.d("User has already published tokens")
        default:
            self.navigationController?.present(ReportInfectionFlowViewController(publishToken: code),
                                               animated: true)
        }
    }
    
    private func showInstructions() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = Text.ReportTitle.localized

        let margin = UIEdgeInsets(top: 20, left: 20, bottom: 30, right: 20)
        let contentView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop,
                                                        margins: margin)
        var top = contentView.snp.top

        let primaryMessage = UILabel(label: Text.ReportMessagePrimary.localized,
                                     font: .heading4,
                                     color: UIColor.Greyscale.black)

        primaryMessage.numberOfLines = 0
        top = contentView.appendView(primaryMessage, top: top)
        
        let secondaryMessage = UILabel(label: Text.ReportMessageSecondary.localized,
                                       font: .bodySmall,
                                       color: UIColor.Greyscale.black)
        
        secondaryMessage.numberOfLines = 0
        top = contentView.appendView(secondaryMessage, spacing: 20, top: top)

        let button = RoundedButton(title: Text.ReportButton.localized) { [unowned self] in
            self.startReportInfectionFlow(with: nil)
        }
        
        top = contentView.appendView(button, spacing: 30, top: top)

        contentView.snp.makeConstraints { make in
            // the content wrapper already contains the space between text and button top edge
            make.bottom.equalTo(top).offset(margin.bottom)
        }
    }

    private func showNotice(image: UIImage?, title: Text? = nil, text: Text) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        
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

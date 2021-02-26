import Foundation
import UIKit
import SnapKit

class SymptomsViewController: UIViewController {
    enum Text : String, Localizable {
        case Heading
        case Body
        case LinkTitle
        case LinkName
        case LinkURL
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func initUI() {
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let titleLabel = InstructionsView.labelItem(Text.Heading.localized,
                                                    font: UIFont.heading2,
                                                    color: UIColor.Greyscale.black,
                                                    spacing: 15)
        
        let textLabel = InstructionsView.labelItem(Text.Body.localized,
                                                    font: UIFont.bodySmall,
                                                    color: UIColor.Greyscale.black,
                                                    spacing: 30)
        
        let link = linkItem(title: Text.LinkTitle,
                                    linkName: Text.LinkName,
                                    url: Text.LinkURL,
                                    spacing: 30)

        let items = [
            titleLabel,
            textLabel,
            link
        ]

        _ = InstructionsView.layoutItems(items, contentView: content)

        items.last!.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    private func linkItem(title: Text, linkName: Text, url: Text, spacing: CGFloat) -> InstructionItem {
        let view = LinkItemCard(title: title.localized, linkName: linkName.localized) { [unowned self] in
            self.openExternalLink(url: URL(string: url.localized)!)
        }
        
        return InstructionItem(view: view, spacing: spacing)
    }
}

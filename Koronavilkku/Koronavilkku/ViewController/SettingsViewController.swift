import Foundation
import UIKit
import SnapKit

class SettingsViewController: UIViewController {
    enum Text : String, Localizable {
        case Heading
        case StatusTitle
        case StatusOn
        case StatusOff
        case StatusLocked
        case SettingsAboutTitle
        case FAQLinkTitle
        case FAQLinkName
        case FAQLinkURL
        case HowItWorksTitle
        case TermsLinkTitle
        case TermsLinkName
        case TermsLinkURL
        case PrivacyLinkTitle
        case PrivacyLinkName
        case PrivacyLinkURL
        case OpenSourceLicenses
        case AppInfoWithVersion
    }
    
    private var statusItem: LinkItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = Text.Heading.localized

        initUI()
        updateStatusItem()
        
        LocalStore.shared.$uiStatus.addObserver(using: {
            self.updateStatusItem()
        })
    }
    
    private func initUI() {
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let items = [
            createStatusItem(),
            sectionTitleItem(text: Text.SettingsAboutTitle),
            aboutGroupItem(),
            appNameAndVersionItem()
        ]

        _ = InstructionsView.layoutItems(items, contentView: content)

        items.last!.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
        
        statusItem.accessibilityTraits = .button
    }
    
    private func sectionTitleItem(text: Text) -> InstructionItem {
        let label = UILabel()
        label.attributedText = NSMutableAttributedString(string: text.localized.uppercased(), attributes: [
            .kern: 0.65,
            .foregroundColor: UIColor.Greyscale.darkGrey,
            .font: UIFont.heading5,
        ])
        return InstructionItem(view: label, spacing: 30)
    }

    private func linkItem<T: Localizable>(title: T, linkName: T? = nil, value: T? = nil, tapped: TapHandler? = nil, url: T? = nil) -> LinkItem {
        return LinkItem(title: title.localized, linkName: linkName?.localized, value: value?.localized, tapped: tapped, url: url?.toURL())
    }
    
    private func linkCard(title: Text, value: Text, tapped: TapHandler?) -> InstructionItem {
        let view = LinkItemCard(title: title.localized, value: value.localized, tapped: tapped)
        return InstructionItem(view: view, spacing: 10)
    }
    
    private func appNameAndVersionItem() -> InstructionItem {
        let versionText = Text.AppInfoWithVersion.localized(with: Environment.default.configuration.version)
        return InstructionsView.labelItem(versionText, font: UIFont.labelTertiary, color: UIColor.Greyscale.darkGrey, spacing: 25)
    }
    
    private func createStatusItem() -> InstructionItem {
        let item = linkCard(title: .StatusTitle, value: .StatusOff, tapped: { self.openChangeStatusView() })
        self.statusItem = (item.view as! LinkItemCard).linkItem
        return item
    }
    
    private func updateStatusItem() {
        var value: Text = .StatusOff
        var enabled = true
        
        switch LocalStore.shared.uiStatus {
        case .on:
            value = .StatusOn
        case .off:
            break
        case .locked:
            value = .StatusLocked
            enabled = false
        case .btOff, .apiDisabled:
            enabled = false
        }

        statusItem.setEnabled(enabled)
        statusItem.setValue(value: value.localized)
    }
    
    private func aboutGroupItem() -> InstructionItem {
        let items = [
            linkItem(title: Text.FAQLinkTitle, linkName: Text.FAQLinkName, url: Text.FAQLinkURL),
            linkItem(title: Text.HowItWorksTitle, tapped: { self.showGuide() }),
            linkItem(title: Text.TermsLinkTitle, linkName: Text.TermsLinkName, url: Text.TermsLinkURL ),
            linkItem(title: Text.PrivacyLinkTitle, linkName: Text.PrivacyLinkName, url: Text.PrivacyLinkURL),
            linkItem(title: Text.OpenSourceLicenses, tapped: {
                self.navigationController?.pushViewController(LicenseListViewController(), animated: true)
            }),
        ]
        items[1].accessibilityTraits = .button

        return InstructionItem(view: LinkItemGroupCard(items: items), spacing: 10)
    }
    
    private func openChangeStatusView() {
        navigationController?.pushViewController(ChangeRadarStatusViewController(), animated: true)
    }
}

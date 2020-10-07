import Foundation
import UIKit
import SnapKit

class SettingsViewController: UIViewController, UINavigationControllerDelegate {
    enum Text : String, Localizable {
        case Heading
        case StatusTitle
        case StatusOn
        case StatusOff
        case StatusLocked
        case ChangeLanguage
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
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // use .heading1 on root view, others use .heading2
        navigationController.largeTitleFont = (viewController === self) ? .heading1 : .heading2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .automatic
        title = Text.Heading.localized
        navigationController?.delegate = self

        initUI()
        updateStatusItem()
        
        LocalStore.shared.$uiStatus.addObserver(using: { [weak self] in
            self?.updateStatusItem()
        })
    }
    
    private func initUI() {
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let items = [
            settingGroupItem(),
            sectionTitleItem(text: Text.SettingsAboutTitle),
            aboutGroupItem(),
            appNameAndVersionItem()
        ]

        _ = InstructionsView.layoutItems(items, contentView: content)

        items.last!.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
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
    
    private func appNameAndVersionItem() -> InstructionItem {
        let versionText = Text.AppInfoWithVersion.localized(with: Environment.default.configuration.version)
        return InstructionsView.labelItem(versionText, font: UIFont.labelTertiary, color: UIColor.Greyscale.darkGrey, spacing: 25)
    }
    
    private func settingGroupItem() -> InstructionItem {
        let status = linkItem(title: Text.StatusTitle, value: Text.StatusOff) { [unowned self] in
            self.navigationController?.pushViewController(ChangeRadarStatusViewController(), animated: true)
        }
        
        let changeLanguage = linkItem(title: Text.ChangeLanguage) { [unowned self] in
            self.navigationController?.pushViewController(ChangeLanguageViewController(), animated: true)
        }
        
        status.accessibilityTraits = .button
        changeLanguage.accessibilityTraits = .button
        statusItem = status

        let items = [
            status,
            changeLanguage
        ]

        return InstructionItem(view: LinkItemGroupCard(items: items), spacing: 10)
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
        let guideLinkItem = linkItem(title: Text.HowItWorksTitle) { [unowned self] in
            self.showGuide()
        }

        let licenseLinkItem = linkItem(title: Text.OpenSourceLicenses) { [unowned self] in
            self.navigationController?.pushViewController(LicenseListViewController(), animated: true)
        }
        
        guideLinkItem.accessibilityTraits = .button
        licenseLinkItem.accessibilityTraits = .button

        let items = [
            linkItem(title: Text.FAQLinkTitle, linkName: Text.FAQLinkName, url: Text.FAQLinkURL),
            guideLinkItem,
            linkItem(title: Text.TermsLinkTitle, linkName: Text.TermsLinkName, url: Text.TermsLinkURL ),
            linkItem(title: Text.PrivacyLinkTitle, linkName: Text.PrivacyLinkName, url: Text.PrivacyLinkURL),
            licenseLinkItem,
        ]

        return InstructionItem(view: LinkItemGroupCard(items: items), spacing: 10)
    }
}

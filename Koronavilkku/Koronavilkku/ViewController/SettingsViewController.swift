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
        var tapped = tapped
        
        if let url = url?.toURL() {
            tapped = { [unowned self] in
                self.openLink(url: url)
            }
        }
        
        return LinkItem(title: title.localized,
                        linkName: linkName?.localized,
                        value: value?.localized,
                        tapped: tapped!)
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
        var value: Text
        var enabled: Bool
        
        switch LocalStore.shared.uiStatus {
        case .on, .notificationsOff:
            value = .StatusOn
            enabled = true

        case .off:
            value = .StatusOff
            enabled = true

        case .locked:
            value = .StatusLocked
            enabled = false

        case .btOff, .apiDisabled:
            value = .StatusOff
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
            linkItem(title: Text.TermsLinkTitle, linkName: Text.TermsLinkName, url: Text.TermsLinkURL),
            linkItem(title: Text.PrivacyLinkTitle, linkName: Text.PrivacyLinkName, url: Text.PrivacyLinkURL),
            licenseLinkItem,
        ]

        return InstructionItem(view: LinkItemGroupCard(items: items), spacing: 10)
    }
}

extension SettingsViewController : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let oldFont = navigationController.largeTitleFont
        let newFont: UIFont = (viewController === self) ? .heading1 : .heading2

        guard oldFont != newFont else { return }
        
        // as the new navigation title is visible during the transition, we need to change it immediately
        navigationController.largeTitleFont = newFont

        // but in case the user cancels the interaction, revert back to the old font
        transitionCoordinator?.notifyWhenInteractionChanges { context in
            if context.isCancelled {
                navigationController.largeTitleFont = oldFont
            }
        }
    }
}

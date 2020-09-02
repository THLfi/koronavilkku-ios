import Foundation
import UIKit
import SnapKit

class ChangeLanguageViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        
        initUI()
    }
    
    private func initUI() {
        navigationItem.title = SettingsViewController.Text.LanguageTitle.localized
        
        view.removeAllSubviews()
        
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let items = Language.all.map { language in
            createLanguageItem(for: language)
        }
        
        _ = InstructionsView.layoutItems(items, contentView: content)
        
        items.last!.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }
    
    private func createLanguageItem(for language: Language) -> InstructionItem {
        let isSelected = language == LocalStore.shared.language
        
        let view = LinkItemCard(title: language.displayName.capitalized, value: nil, tapped: { self.languageSelected(language) })
        view.linkItem.accessibilityTraits = .button
        view.linkItem.indicator.image = isSelected ? UIImage(named: "check") : nil
        view.linkItem.indicator.snp.updateConstraints { make in
            make.size.equalTo(24)
        }
        
        return InstructionItem(view: view, spacing: 10)
    }
    
    private func languageSelected(_ language: Language) {
        LocalStore.shared.language = language
        
        initUI()
        
        navigationController?.popViewController(animated: true)
    }
}

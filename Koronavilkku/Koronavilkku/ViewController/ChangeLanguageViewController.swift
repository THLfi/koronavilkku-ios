import Foundation
import UIKit
import SnapKit

class ChangeLanguageViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = SettingsViewController.Text.LanguageTitle.localized

        initUI()
    }
    
    private func initUI() {
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
        let view = LinkItemCard(title: language.displayName, value: nil, tapped: { self.languageSelected(language) })
        return InstructionItem(view: view, spacing: 10)
    }
    
    private func languageSelected(_ language: Language) {
        LocalStore.shared.language = language
        
        navigationItem.title = SettingsViewController.Text.LanguageTitle.localized
        
        navigationController?.popViewController(animated: true)
    }
}

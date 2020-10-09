import Foundation
import UIKit
import SnapKit

class LinkLanguageViewController: UIViewController {

    enum Text : String, Localizable {
        case Title
        case SymptomsAssesmentSubtitle
        case SymptomsAssesmentText
        case ContactRequestSubtitle
        case ContactRequestText
        case Finnish
        case Swedish
        case English
    }

    private let repository: MunicipalityRepository
    private let municipality: Municipality
    private let target: OmaoloTarget
    
    init(_ repository: MunicipalityRepository, _ municipality: Municipality, _ target: OmaoloTarget) {
        self.repository = repository
        self.municipality = municipality
        self.target = target
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = Text.Title.localized

        initUI()
    }

    private func initUI() {
        let contentView = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        var top = contentView.snp.top
        
        let titleText: Text
        let infoText: Text
        
        switch target {
        case .contact:
            titleText = Text.ContactRequestSubtitle
            infoText = Text.ContactRequestText
        case .makeEvaluation:
            titleText = Text.SymptomsAssesmentSubtitle
            infoText = Text.SymptomsAssesmentText
        }
        
        let title = UILabel(label: titleText.localized, font: UIFont.heading2, color: UIColor.Greyscale.black)
        title.numberOfLines = 0
        top = contentView.appendView(title, spacing: 20, top: top)
        
        let info = UILabel(label: infoText.localized, font: UIFont.bodyLarge, color: UIColor.Greyscale.black)
        info.numberOfLines = 0
        top = contentView.appendView(info, spacing: 16, top: top)
        
        let languageNames = [
            OmaoloLanguageId.finnish: Text.Finnish,
            OmaoloLanguageId.swedish: Text.Swedish,
            OmaoloLanguageId.english: Text.English
        ]
        
        var spacing: CGFloat = 30
        
        municipality.omaolo.supportedServiceLanguageIdentifiers()
            .map { langId in SelectableLanguage(identifier: langId, name: languageNames[langId]?.localized ?? langId) }
            .forEach { lang in
                let linkCard = LinkItemCard(title: lang.name, linkName: nil, value: nil, tapped: { [unowned self] in
                    self.openLink(language: lang.identifier)
                })
                
                top = contentView.appendView(linkCard, spacing: spacing, top: top)
                spacing = 20
            }

        contentView.subviews.last!.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    private func openLink(language: String) {
        let url = repository.getOmaoloLink(for: target, in: municipality, language: language)
        self.openExternalLink(url: url)
    }
}

fileprivate struct SelectableLanguage {
    let identifier: String
    let name: String
}

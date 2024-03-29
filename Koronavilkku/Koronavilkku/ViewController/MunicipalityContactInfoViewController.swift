import Foundation
import UIKit
import SnapKit

class MunicipalityContactInfoViewController: UIViewController {
    
    enum Text : String, Localizable {
        case SymptomAssesmentTitle
        case SymptomAssesmentDescription
        case SymptomAssesmentButton
        case SymptomAssesmentHelp
        case SecondaryContactTitle
        case SecondaryContactBody
        case ContactFirstTitle
        case ContactFirstBody
    }
    
    private let municipalityRepository = Environment.default.municipalityRepository
    var municipality: Municipality!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Prevent flaky animation when transitioning from table view... yes, this does it
        self.view.backgroundColor = UIColor.Secondary.blueBackdrop
        
        setupNavigationBar()
        initUI()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = municipality.name.localeString
        navigationController?.navigationBar.barTintColor = UIColor.Secondary.blueBackdrop
        navigationController?.navigationBar.tintColor = UIColor.Primary.blue
        navigationController?.navigationItem.titleView?.isHidden = true
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.Greyscale.black,
            NSAttributedString.Key.font: UIFont.labelPrimary
        ]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    private func initUI() {
        
        let contentView = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 60, right: 20)
        )
        
        var top = contentView.snp.top
        
        if municipality.omaolo.available(service: .SymptomAssessment) {
            let infoView = InfoViewWithButton(title: Text.SymptomAssesmentTitle.localized,
                                              descriptionText: Text.SymptomAssesmentDescription.localized,
                                              buttonTitle: Text.SymptomAssesmentButton.localized,
                                              bottomText: Text.SymptomAssesmentHelp.localized,
                                              buttonTapped: { [unowned self] in self.openOmaoloLink(target: .makeEvaluation) })
            top = contentView.appendView(infoView, top: top)

            let titleLabel = UILabel(label: Text.SecondaryContactTitle.localized,
                                     font: UIFont.heading3,
                                     color: UIColor.Greyscale.black)
            titleLabel.numberOfLines = 0
            titleLabel.setLineHeight(0.95)
            top = contentView.appendView(titleLabel, spacing: 30, top: top)
            
            let messageLabel = UILabel(label: Text.SecondaryContactBody.localized,
                                       font: .bodySmall,
                                       color: UIColor.Greyscale.darkGrey)
            
            messageLabel.numberOfLines = 0
            top = contentView.appendView(messageLabel, spacing: 10, top: top)
        }

        let contactInformationView = MunicipalityContactInformationView(municipality: municipality) { [unowned self] in
            self.openOmaoloLink(target: .contact)
        }
        
        top = contentView.appendView(contactInformationView, spacing: 20, top: top)
        
        let symptomsInfo = UILabel(label: Text.ContactFirstTitle.localized, font: .heading4, color: UIColor.Greyscale.black)
        symptomsInfo.numberOfLines = 0
        top = contentView.appendView(symptomsInfo, spacing: 30, top: top)
        
        let symptomsText = UILabel(label: Text.ContactFirstBody.localized, font: .bodySmall, color: UIColor.Greyscale.black)
        symptomsText.numberOfLines = 0
        top = contentView.appendView(symptomsText, spacing: 10, top: top)
        
        symptomsText.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }
    
    private func openOmaoloLink(target: OmaoloTarget) {
        let languages = municipality.omaolo.supportedServiceLanguageIdentifiers()
        
        if languages.isEmpty || languages.count == 1 {
            let url = municipalityRepository.getOmaoloLink(for: target, in: municipality, language: languages.first ?? Omaolo.defaultLanguageId)
            self.openExternalLink(url: url)
            
        } else {
            let langSelector = LinkLanguageViewController(municipalityRepository, municipality, target)
            self.navigationController?.pushViewController(langSelector, animated: true)
        }
    }
}

#if DEBUG

import SwiftUI

struct MunicipalityContactInfoViewControllerController_Preview: PreviewProvider {
    
    static var previews: some View = Group {
        createPreview(for: {
            let municipality = Municipality(code: "1234",
                                            name: MunicipalityName(fi: "Pirkkala", sv: "Birkala"),
                                            omaolo: Omaolo(available: true,
                                                           serviceLanguages: ServiceLanguages(fi: true, sv: true, en: true),
                                                           symptomAssessmentOnly: false),
                                            contact: [
                                                Contact(title: Localized(fi: "Pirkkalan terveyskeskus",
                                                                         sv: nil,
                                                                         en: nil),
                                                        phoneNumber: "+358 555 123",
                                                        info: Localized(fi: "Maanantai - Perjantai 8-16",
                                                                        sv: nil,
                                                                        en: nil)),
                                            ])
            let vc = MunicipalityContactInfoViewController()
            vc.municipality = municipality
            return vc
        }())
        
        createPreview(for: {
            let municipality = Municipality(code: "1234",
                                            name: MunicipalityName(fi: "Pirkkala", sv: "Birkala"),
                                            omaolo: Omaolo(available: true,
                                                           serviceLanguages: ServiceLanguages(fi: true, sv: true, en: true),
                                                           symptomAssessmentOnly: true),
                                            contact: [
                                                Contact(title: Localized(fi: "Pirkkalan terveyskeskus",
                                                                         sv: nil,
                                                                         en: nil),
                                                        phoneNumber: "+358 555 123",
                                                        info: Localized(fi: "Maanantai - Perjantai 8-16",
                                                                        sv: nil,
                                                                        en: nil)),
                                            ])
            let vc = MunicipalityContactInfoViewController()
            vc.municipality = municipality
            return vc
        }())

        createPreview(for: {
            let municipality = Municipality(code: "1234",
                                            name: MunicipalityName(fi: "Pirkkala", sv: "Birkala"),
                                            omaolo: Omaolo(available: false,
                                                           serviceLanguages: nil,
                                                           symptomAssessmentOnly: nil),
                                            contact: [
                                                Contact(title: Localized(fi: "Pirkkalan terveyskeskus",
                                                                         sv: nil,
                                                                         en: nil),
                                                        phoneNumber: "+358 555 123",
                                                        info: Localized(fi: "Maanantai - Perjantai 8-16",
                                                                        sv: nil,
                                                                        en: nil)),
                                            ])
            let vc = MunicipalityContactInfoViewController()
            vc.municipality = municipality
            return vc
        }())
    }
}

#endif

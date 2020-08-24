import Foundation
import UIKit
import SnapKit

class MunicipalityContactInformationView: UIView {

    let municipality: Municipality
    let contactRequestHandler: TapHandler
    
    init(municipality: Municipality, contactRequestHandler: @escaping TapHandler) {
        self.municipality = municipality
        self.contactRequestHandler = contactRequestHandler
        super.init(frame: .zero)
        
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        var top = self.snp.top
        var spacing: CGFloat = 0
        
        if municipality.omaolo.available {
            let omaolo = LinkItemCard(title: Translation.ContactRequestItemTitle.localized,
                                  linkName: Translation.ContactRequestItemInfo.localized,
                                  tapped: contactRequestHandler)
            top = appendView(omaolo, spacing: spacing, top: top)
            spacing = 10
        }
        
        municipality.localizedContacts.enumerated().forEach { index, contact in
            let view = ContactItemCard(contact: contact)
            top = appendView(view, spacing: spacing, top: top)
            spacing = 10
        }

        if let last = subviews.last {
            last.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }
}

#if DEBUG
import SwiftUI

struct MunicipalityContactInformationViewPreview: PreviewProvider {
    static var previews: some View {
        createPreview(
            for: MunicipalityContactInformationView(municipality: Municipality(
                                                        code: "1234",
                                                        name: MunicipalityName(fi: "Pirkkala", sv: "Birkala"),
                                                        omaolo: Omaolo(available: true, serviceLanguages: ServiceLanguages(fi: true, sv: true, en: true)),
                                                        contact: [
                                                            Contact(title: Localized(fi: "Pirkkalan terveyskeskus",
                                                                                     sv: "Birkala hälsovårdscentral",
                                                                                     en: nil),
                                                                    phoneNumber: "+358 555 1234",
                                                                    info: Localized(fi: "Maanantai - Perjantai 8-16",
                                                                                    sv: "Måndag - Fredag 8-16",
                                                                                    en: nil))
                                                            ]),
                                                                
            contactRequestHandler: { }),
            width: 335,
            height: 292
        )
    }
}
#endif

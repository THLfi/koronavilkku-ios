import Foundation
import UIKit
import SnapKit

class ContactItemCard: CardElement {
    let contact: LocalizedContact
    
    init(contact: LocalizedContact) {
        self.contact = contact
        super.init()
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        let iconView = createImageView()
        self.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.height.width.equalTo(22)
        }
        
        let contactWrapper = UIView()
        self.addSubview(contactWrapper)
        var top = contactWrapper.snp.top
        
        let title = UILabel(label: contact.title,
                            font: UIFont.bodySmall,
                            color: UIColor.Greyscale.black)
        title.numberOfLines = 0
        top = contactWrapper.appendView(title, top: top)
        
        // TODO should we instead use a label + add tap listener to entire card area that would initiate phone call?
        let phoneNumber = UITextView()
        phoneNumber.text = contact.phoneNumber
        phoneNumber.font = UIFont.heading4
        phoneNumber.textColor = UIColor.Primary.blue
        phoneNumber.isEditable = false
        phoneNumber.isScrollEnabled = false
        phoneNumber.isSelectable = true
        phoneNumber.dataDetectorTypes = .phoneNumber
        phoneNumber.backgroundColor = .clear
        phoneNumber.textContainerInset = .zero
        phoneNumber.textContainer.lineFragmentPadding = 0
        top = contactWrapper.appendView(phoneNumber, top: top)
        
        let info = UILabel(label: contact.info,
                           font: UIFont.labelTertiary,
                           color: UIColor.Greyscale.darkGrey)
        info.numberOfLines = 0
        top = contactWrapper.appendView(info, spacing: 4, top: top)
        
        info.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
        
        contactWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(iconView.snp.left).offset(-8)
        }
    }
    
    private func createImageView() -> UIImageView {
        let image = UIImage(named: "phone")!
                    .withTintColor(UIColor.Primary.blue)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }
}


#if DEBUG
import SwiftUI

struct ContactItemCardPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: ContactItemCard(contact:
            LocalizedContact(title: "Pirkkalan terveyskeskus",
                             phoneNumber: "+358 555 1234",
                             info: "maanantai-perjantai 8-16")),
        width: 335,
        height: 84
    )
}
#endif

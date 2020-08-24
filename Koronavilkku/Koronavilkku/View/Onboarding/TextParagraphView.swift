import Foundation
import UIKit
import SnapKit

class TextParagraphView: UIView {
    
    let title: String
    let content: String
    let image: String
    let divider: Bool
    
    init(title: String, content: String, image: String, divider: Bool = true) {
        self.title = title
        self.content = content
        self.image = image
        self.divider = divider
        
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        
        let imageView = UIImageView(image: UIImage(named: image)!.withTintColor(UIColor.Primary.blue))
        imageView.contentMode = .scaleAspectFit
        
        self.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        let titleLabel = UILabel(label: title,
                                 font: UIFont.heading4,
                                 color: UIColor.Greyscale.black)
        self.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(19)
            make.right.equalToSuperview()
        }
        
        let contentLabel = UILabel(label: content,
                                   font: UIFont.bodySmall,
                                   color: UIColor.Greyscale.darkGrey)
        contentLabel.numberOfLines = 0
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalTo(titleLabel)
        }
        
        if divider {
            let bottomBorder = UIView.createDivider()
            self.addSubview(bottomBorder)
            
            bottomBorder.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(1)
                make.top.equalTo(contentLabel.snp.bottom).offset(20).priority(2)
            }

        } else {
            contentLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }
}

#if DEBUG
import SwiftUI

struct TextParagraphViewPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: TextParagraphView(title: "Henkilöihin liittyvät tiedot",
                               content: "Koronavilkku ei tallenna nimeäsi, syntymäaikaasi tai yhteystietojasi.\n\nKoronavilkku ei pysty selvittämään sinun tai tapaamiesi ihmisten henkilöllisyyksiä.",
                               image: "user"),
        width: 295,
        height: 250
    )
}
#endif

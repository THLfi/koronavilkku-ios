import Foundation
import UIKit
import SnapKit

final class TableViewCell: UITableViewCell {
    
    var titleLabel: UILabel!
    var secondaryLabel: UILabel!
    
    init(title: String, secondaryTitle: String? = nil, identifier: String) {
        super.init(style: .default, reuseIdentifier: identifier)
        createUI(title, secondaryTitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createUI(_ title: String, _ secondaryTitle: String?){
        titleLabel = UILabel(label: title,
                            font: UIFont.bodySmall,
                            color: UIColor.Greyscale.black)
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.width.greaterThanOrEqualTo(150)
        }
        
       
        let chevron = UIImageView(image: UIImage(named: "chevron-right")!)
        chevron.contentMode = .scaleAspectFit
        self.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-28)
            make.height.equalTo(14)
            make.width.equalTo(8)
        }
        
        secondaryLabel = UILabel(label: secondaryTitle ?? "",
                                     font: UIFont.bodySmall,
                                     color: UIColor.Greyscale.darkGrey)
        secondaryLabel.textAlignment = .right
        self.addSubview(secondaryLabel)
        
        secondaryLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(chevron.snp.left).offset(-18)
            make.left.equalTo(titleLabel.snp.right).offset(32)
        }
        self.backgroundView = UIView(frame: self.bounds)
    }
}

#if DEBUG
import SwiftUI

struct TableViewCellPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: TableViewCell(title: "Altistusloki ja ilmoitukset",
                           secondaryTitle: "Päällä",
                           identifier: "foo"),
        width: 335,
        height: 64
    )
}
#endif

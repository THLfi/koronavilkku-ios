import Foundation
import UIKit
import SnapKit

final class TableViewHeader: UIView {
    
    init(title: String) {
        super.init(frame: .zero)
        createUI(titleString: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createUI(titleString: String){
        self.backgroundColor = UIColor.Secondary.blueBackdrop
        
        let title = UILabel(label: titleString,
                            font: UIFont.heading5,
                            color: UIColor.Greyscale.darkGrey)
        self.addSubview(title)
        
        title.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

#if DEBUG
import SwiftUI

struct TableViewHeaderPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: TableViewHeader(title: "COVID-19-ALTISTUSLOKI JA -ILMOITUKSET"),
        width: 258,
        height: 25
    )
}
#endif

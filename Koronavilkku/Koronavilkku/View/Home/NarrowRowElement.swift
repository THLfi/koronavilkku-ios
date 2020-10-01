import Foundation
import UIKit
import SnapKit

final class NarrowRowElement: CardElement {

    let title: String
    let tapped: () -> ()
    var image: UIImage?

    init(image: UIImage,
         title: String,
         tapped: @escaping () -> () = { Log.d("Not implemented") }) {
        
        self.image = image
        self.title = title
        self.tapped = tapped
        
        super.init()
        createSubViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapGesture() {
        self.tapped()
    }

    private func createSubViews() {
        
        let imageView = UIImageView(image: self.image)
        self.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.top.equalToSuperview().offset(16)
        }
        
        let titleLabel = UILabel(label: title, font: UIFont.bodySmall, color: UIColor.Greyscale.black)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-14)
        }
        
        titleLabel.isAccessibilityElement = false
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
    }
}

#if DEBUG
import SwiftUI

struct NarrowRowElementPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: NarrowRowElement(
            image: UIImage(named: "finland-map")!,
            title: "Tilastot"
        ) {
            Log.d("Debug tapped")
        },
        width: 158,
        height: 120
    )
}
#endif

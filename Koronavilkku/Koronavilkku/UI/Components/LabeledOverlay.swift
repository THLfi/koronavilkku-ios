import Foundation
import UIKit

class LabeledOverlay: UIView {
    
    let label: String
    
    init(label: String) {
        self.label = label
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        self.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let textLabel = UILabel(label: self.label,
                                font: UIFont.heading2,
                                color: UIColor.white)
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        self.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(60)
            make.centerX.equalToSuperview()
            make.height.equalTo(100)
        }
    }
}

extension UIViewController {

    func showLabeledOverlay(with text: String) -> LabeledOverlay {
        let overlay = LabeledOverlay(label: text)
        self.view.addSubview(overlay)
        
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return overlay
    }
    
    func hideshowLabeledOverlay(_ overlay: LabeledOverlay) {
        overlay.removeFromSuperview()
    }
}

#if DEBUG
import SwiftUI

struct LabeledOverlayPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: LabeledOverlay(label: "Jatka käyttöönottoa valitsemalla \"Salli\""),
        width: 375,
        height: 667
    )
}
#endif

import UIKit

class OnboardingDoneView: UIView {
    
    init(callback: @escaping () -> ()) {
        super.init(frame: .zero)
        initUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: callback)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        let container = UIView()
        self.addSubview(container)
        container.snp.makeConstraints { make in
            make.center.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        }
        
        let imageView = UIImageView(image: UIImage(named: "ok")!)
        imageView.contentMode = .scaleAspectFit
        container.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(150)
        }
        
        let label = UILabel(label: Translation.OnboardingDone.localized, font: UIFont.heading3, color: UIColor.Greyscale.black)
        label.numberOfLines = 0
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(30)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

#if DEBUG
import SwiftUI

struct OnboardingDoneViewPreview: PreviewProvider {
    static var previews: some View =
        createPreview(for: OnboardingDoneView(callback: {}),
                      width: 375,
                      height: 667)
}
#endif

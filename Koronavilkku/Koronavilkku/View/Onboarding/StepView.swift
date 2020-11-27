
import Foundation
import UIKit
import SnapKit

class StepView: UIView {

    let headerLabel = UILabel()
    let contentTextView = UILabel()
    
    let image: UIImage
    let header: String
    let content: String
    let extraContent: [UIView]?
    
    init(image: UIImage, header: String, content: String, extraContent: [UIView]?) {
        self.image = image
        self.header = header
        self.content = content
        self.extraContent = extraContent
        
        super.init(frame: .zero)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        self.backgroundColor = UIColor.Greyscale.white
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(180)
        }
        
        headerLabel.accessibilityTraits = .header
        headerLabel.text = header
        headerLabel.font = .heading2
        headerLabel.numberOfLines = 0
        headerLabel.setLineHeight(0.84)
        self.addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }
        
        contentTextView.text = content
        contentTextView.font = UIFont.bodySmall
        contentTextView.textColor = UIColor.Greyscale.black
        contentTextView.translatesAutoresizingMaskIntoConstraints = true
        contentTextView.numberOfLines = 0
        
        self.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(40)
        }
        
        var bottomView: UIView = contentTextView
        
        if let extraContent = self.extraContent {
            let extraContentView = createWrapper(for: extraContent)
            self.addSubview(extraContentView)
            extraContentView.snp.makeConstraints { make in
                make.top.equalTo(contentTextView.snp.bottom).offset(34)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
            bottomView = extraContentView
        }
        
        bottomView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-160)
        }
    }
    
    private func createWrapper(for extraContent: [UIView]) -> UIView {
        let wrapper = UIView(frame: .zero)
        switch extraContent.count {
        case ...0: return UIView()
        default:
            var lastComponent: UIView?
            extraContent.enumerated().forEach { (index, content) in
                wrapper.addSubview(content)
                content.snp.makeConstraints { make in
                    if let lastComponent = lastComponent {
                        make.top.equalTo(lastComponent.snp.bottom).offset(20)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.left.equalToSuperview().offset(20)
                    make.right.equalToSuperview().offset(-20)
                }
                lastComponent = content
            }
            
            guard let _ = lastComponent else { return wrapper }
            
            wrapper.snp.makeConstraints { make in
                make.bottom.equalTo(lastComponent!)
            }
            return wrapper
        }
    }
}

#if DEBUG
import SwiftUI

struct StepViewPreview: PreviewProvider {
    static var previews: some View = createPreview(
        for: StepView(image: UIImage(named: "allow-notifications")!,
                      header: Translation.OnboardingIntroTitle.localized,
                      content: Translation.OnboardingIntroText.localized,
                      extraContent: [
                        LinkLabel(label: "Katso, miten sovellus toimii",
                                  font: UIFont.heading4,
                                  color: UIColor.Primary.blue,
                                  underline: false) {}
        ]),
        width: 375,
        height: 667
    )
}
#endif

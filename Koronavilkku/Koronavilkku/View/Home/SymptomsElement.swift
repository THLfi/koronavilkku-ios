import UIKit

final class SymptomsElement: WideRowElement {
    enum Text : String, Localizable {
        case Title
        case Body
    }
    
    let margin = UIEdgeInsets(top: 20, left: 20, bottom: -20, right: -20)

    override func createSubViews() {
        super.createSubViews()

        let container = UIView()
        let imageView = UIImageView(image: UIImage(named: "symptoms-cropped")!)
        let textContainer = UIView()
        let titleView = createTitleLabel(title: Text.Title.localized)
        let bodyView = createBodyLabel(body: Text.Body.localized)
        
        self.addSubview(container)
        container.addSubview(textContainer)
        container.addSubview(imageView)
        textContainer.addSubview(titleView)
        textContainer.addSubview(bodyView)
                
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        textContainer.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(margin.top)
            make.bottom.lessThanOrEqualToSuperview().offset(margin.bottom)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalTo(imageView.snp.left)
        }

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        bodyView.snp.makeConstraints{ make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.bottom.left.right.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.top.equalToSuperview().priority(.low)
            make.size.equalTo(CGSize(width: 135, height: 110))
        }
        
        container.clipsToBounds = true
        container.layer.cornerRadius = cornerRadius
        titleView.isAccessibilityElement = false
        bodyView.isAccessibilityElement = false
        imageView.accessibilityTraits = .none
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = titleView.text
        self.accessibilityValue = bodyView.text
    }
}

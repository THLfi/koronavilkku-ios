import UIKit

class InfoButton : CardElement {
    private var titleView: UILabel!
    private var subtitleView: UILabel!
    private var tapRecognizer: UITapGestureRecognizer!
    private let tapped: () -> ()
    
    var title: String {
        didSet {
            titleView.text = title
            accessibilityLabel = title
        }
    }
    
    var subtitle: String {
        didSet {
            subtitleView.text = subtitle
            accessibilityValue = subtitle
        }
    }
    
    init(title: String, subtitle: String, tapped: @escaping () -> ()) {
        self.title = title
        self.subtitle = subtitle
        self.tapped = tapped
        super.init()

        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler))
        self.addGestureRecognizer(self.tapRecognizer)
        
        self.accessibilityTraits = .button
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
        self.accessibilityValue = subtitle
        
        let imageView = UIImageView(image: UIImage(named: "info-mark")?.withTintColor(UIColor.Primary.blue))
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        let titleView = UILabel(label: title, font: .bodySmall, color: UIColor.Greyscale.black)
        titleView.numberOfLines = 0
        addSubview(titleView)
        
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.left.equalToSuperview().inset(20)
            make.right.equalTo(imageView.snp.left).offset(-10)
        }
        
        let subtitleView = UILabel(label: subtitle, font: .labelTertiary, color: UIColor.Greyscale.darkGrey)
        subtitleView.numberOfLines = 0
        addSubview(subtitleView)

        subtitleView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(2)
            make.left.equalToSuperview().inset(20)
            make.right.equalTo(imageView.snp.left).offset(-10)
            make.bottom.equalToSuperview().inset(13)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapGestureHandler() {
        tapped()
    }
}

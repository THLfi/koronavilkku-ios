import UIKit

class Badge: UIView {
    var horizontalInset = CGFloat(11)
    var verticalInset = CGFloat(0)
    var label: UILabel
    
    init(label: String,
         backgroundColor: UIColor = UIColor.Primary.blue,
         textColor: UIColor = UIColor.Greyscale.white) {
        
        self.label = UILabel(label: label, font: .heading4, color: textColor)
        super.init(frame: .zero)
        
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = 100
        
        addSubview(self.label)

        let insets = UIEdgeInsets(top: verticalInset,
                                  left: horizontalInset,
                                  bottom: verticalInset,
                                  right: horizontalInset)
        
        self.label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = bounds.height / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

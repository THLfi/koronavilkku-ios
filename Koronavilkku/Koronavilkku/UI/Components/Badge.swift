import UIKit

class Badge: UIView {
    var horizontalInset = CGFloat(11)
    var verticalInset = CGFloat(0)
    var label: UILabel
    
    init(label: String,
         backgroundColor: UIColor = UIColor.Primary.blue,
         textColor: UIColor = UIColor.Greyscale.white) {
        
        self.label = UILabel(label: label, font: .heading4, color: textColor)
        self.label.textAlignment = .center
        super.init(frame: .zero)
        
        self.backgroundColor = backgroundColor
        
        addSubview(self.label)

        let insets = UIEdgeInsets(top: verticalInset,
                                  left: horizontalInset,
                                  bottom: verticalInset,
                                  right: horizontalInset)
        
        self.label.snp.makeConstraints { [unowned self] make in
            make.edges.equalToSuperview().inset(insets)
            
            // make sure the element is slightly wider than higher to avoid funny corner radius shapes
            make.width.greaterThanOrEqualTo(self.label.snp.height).offset(horizontalInset * -1.5)
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

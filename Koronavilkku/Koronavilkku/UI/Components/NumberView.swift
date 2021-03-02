import UIKit

class NumberView : UIView {
    init(number: Int) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.Primary.blue

        let label = UILabel(label: "\(number)", font: .heading4, color: UIColor.Greyscale.white)
        label.textAlignment = .center
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        snp.makeConstraints { make in
            make.width.equalTo(snp.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

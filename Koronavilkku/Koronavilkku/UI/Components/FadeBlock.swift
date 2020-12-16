import UIKit

class FadeBlock: UIView {
    
    private let gradientLayer: CAGradientLayer
    
    init(color: UIColor = UIColor.Greyscale.white) {
        self.gradientLayer = CAGradientLayer()
        
        super.init(frame: .zero)
        
        gradientLayer.colors = [color.withAlphaComponent(0.0).cgColor, color.cgColor]
        gradientLayer.locations = [0, 0.666]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        layer.addSublayer(gradientLayer)
        
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

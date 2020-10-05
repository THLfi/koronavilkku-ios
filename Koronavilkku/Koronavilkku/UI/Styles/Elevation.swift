import UIKit

enum Elevation {
    case elevation1
    case elevation2
    
    var opacity: Float {
        switch self {
        case .elevation1:
            return 0.1
        case .elevation2:
            return 0.2
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .elevation1:
            return 14
        case .elevation2:
            return 20
        }
    }
}

extension UIView {
    func setElevation(_ elevation: Elevation) {
        layer.shadowColor = .dropShadow
        layer.shadowOpacity = elevation.opacity
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = elevation.radius
    }
    
    func updateShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}

import Foundation
import UIKit

extension UIColor {
    struct Greyscale {
        static let black = UIColor(red: 0.188, green: 0.188, blue: 0.188, alpha: 1)
        static let darkGrey = UIColor(red: 0.376, green: 0.376, blue: 0.376, alpha: 1)
        static let mediumGrey = UIColor(red: 0.549, green: 0.549, blue: 0.549, alpha: 1)
        static let lightGrey = UIColor(red: 0.698, green: 0.698, blue: 0.698, alpha: 1)
        static let borderGrey = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        static let backdropGrey = UIColor(red: 0.938, green: 0.938, blue: 0.938, alpha: 1)
        static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    struct Primary {
        static let blue = UIColor(red: 0.141, green: 0.447, blue: 0.698, alpha: 1)
        static let violet = UIColor(red: 0.569, green: 0.443, blue: 0.737, alpha: 1)
        static let pink = UIColor(red: 0.737, green: 0.294, blue: 0.655, alpha: 1)
        static let red = UIColor(red: 0.839, green: 0.255, blue: 0.463, alpha: 1)
        static let brown = UIColor(red: 0.698, green: 0.427, blue: 0.035, alpha: 1)
        static let cyan = UIColor(red: 0.161, green: 0.627, blue: 0.757, alpha: 1)
    }
    
    struct Secondary {
        static let lightBlue = UIColor(red: 0.463, green: 0.6, blue: 0.839, alpha: 1)
        static let attentionYellow = UIColor(red: 0.98, green: 0.651, blue: 0.102, alpha: 1)
        static let blueBackdrop = UIColor(red: 0.949, green: 0.965, blue: 0.984, alpha: 1)
        static let tableHeaderBackground = UIColor(red: 0.906, green:0.929, blue:0.957, alpha: 1)
        static let buttonHighlightedBackground = UIColor(red: 0.077, green: 0.362, blue: 0.596, alpha: 1)
    }
}

extension CGColor {
    static let dropShadow = UIColor(red: 0.136, green: 0.295, blue: 0.425, alpha: 1).cgColor
}

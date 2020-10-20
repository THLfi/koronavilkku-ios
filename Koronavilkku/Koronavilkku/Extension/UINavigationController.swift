import Foundation
import UIKit

extension UINavigationController {
    func setDefaultStyle() {
        navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        view.backgroundColor = UIColor.Secondary.blueBackdrop
        navigationBar.tintColor = UIColor.Primary.blue
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.Secondary.blueBackdrop
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .font: UIFont.heading1,
            .foregroundColor: UIColor.Greyscale.black
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.labelPrimary,
            .foregroundColor: UIColor.Greyscale.black
        ]

        appearance.setBackIndicatorImage(
            UIImage.init(named: "arrow-left"),
            transitionMaskImage: UIImage.init(named: "arrow-left")
        )
        
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.standardAppearance = appearance
    }
    
    var largeTitleFont: UIFont? {
        get {
            navigationBar.standardAppearance.largeTitleTextAttributes[.font] as? UIFont
        }
        
        set {
            guard let font = newValue, font !== largeTitleFont else {
                return
            }
            
            let appearance = navigationBar.standardAppearance.copy()

            appearance.largeTitleTextAttributes = [
                .font: font
            ]
            
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
}

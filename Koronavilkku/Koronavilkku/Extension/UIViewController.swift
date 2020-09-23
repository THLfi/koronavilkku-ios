import Foundation
import UIKit

extension UIViewController {
    func showAlert(title: String, message: String, buttonText: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonText, style: .default, handler: handler))
        self.present(alert, animated: true)
    }
    
    func showConfirmation(title: String, message: String, okText: String, cancelText: String, destructive: Bool, handler: @escaping (_ confirmed: Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let style: UIAlertAction.Style = destructive ? .destructive : .default
        let actionHandler = { (action: UIAlertAction) -> Void in
            handler(action.style == style)
        }
        
        alert.addAction(UIAlertAction(title: okText, style: style, handler: actionHandler))
        alert.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: actionHandler))
        self.present(alert, animated: true)
    }
    
    func showGuide() {
        self.present(HowItWorksViewController(), animated: true)
    }
}

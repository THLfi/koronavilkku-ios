import Foundation
import UIKit
import SafariServices

class LinkHandler {
    
    static let shared = LinkHandler()
    
    func open(_ url: URL, inApp: Bool) {
        let app = UIApplication.shared
        
        if inApp, var vc = app.windows.first?.rootViewController {
            while vc.presentedViewController != nil {
                vc = vc.presentedViewController!
            }
            
            let safariController = SFSafariViewController(url: url)
            vc.present(safariController, animated: true)
        } else {
            app.open(url)
        }
    }
}

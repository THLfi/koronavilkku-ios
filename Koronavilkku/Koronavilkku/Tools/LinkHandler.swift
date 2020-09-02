import Foundation
import UIKit
import SafariServices

class LinkHandler {
    
    static let shared = LinkHandler()
    
    func open(_ url: URL) {
        let app = UIApplication.shared
        guard var vc = app.windows.first?.rootViewController else {
            app.open(url)
            return
        }
        
        while vc.presentedViewController != nil {
            vc = vc.presentedViewController!
        }
        
        let safariController = SFSafariViewController(url: url)
        vc.present(safariController, animated: true)
    }
}

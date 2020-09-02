import Foundation
import UIKit
import SafariServices

class LinkHandler {
    
    static let shared = LinkHandler()
    
    func open(_ url: URL) {
        let app = UIApplication.shared
        guard let vc = app.windows.first?.rootViewController else {
            app.open(url)
            return
        }
        
        let safariController = SFSafariViewController(url: url)
        vc.present(safariController, animated: true)
    }
}

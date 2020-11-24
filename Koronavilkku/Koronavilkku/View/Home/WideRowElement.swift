import Combine
import Foundation
import SnapKit
import UIKit

class WideRowElement: CardElement {
    
    let tapped: () -> ()

    init(tapped: @escaping () -> () = {}) {
        self.tapped = tapped
        super.init()
        initUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        self.addGestureRecognizer(tapGesture)
        createSubViews()
    }
 
    @objc func tapHandler() {
        self.tapped()
    }

    func createSubViews() {
        self.removeAllSubviews()
    }
    
    func createTitleLabel(title: String) -> UILabel {
        let titleView = UILabel(label: title, font: UIFont.heading4, color: UIColor.Greyscale.black)
        titleView.numberOfLines = 0
        return titleView
    }

    func createBodyLabel(body: String) -> UILabel {
        // TODO line height - https://stackoverflow.com/a/5513730
        let bodyLabel = UILabel(label: body, font: UIFont.labelTertiary, color: UIColor.Greyscale.black)
        bodyLabel.numberOfLines = 0
        if #available(iOS 14.0, *) {
            bodyLabel.lineBreakStrategy = .hangulWordPriority
        }
        return bodyLabel
    }
    
    func createImageView(imageNamed: String, addShadow: Bool = true) -> UIView {
        let image = UIImage(named: imageNamed)
        let imageView = UIImageView(image: image)
        
        if !addShadow {
            return imageView
        }
        
        imageView.setElevation(.elevation1)

        let wrapper = UIView()
        wrapper.setElevation(.elevation2)
        
        let shadowPath = UIBezierPath(ovalIn: imageView.bounds).cgPath
        wrapper.layer.shadowPath = shadowPath
        imageView.layer.shadowPath = shadowPath

        wrapper.addSubview(imageView)
        return wrapper
    }
}

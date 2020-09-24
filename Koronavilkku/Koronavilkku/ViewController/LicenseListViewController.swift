import SnapKit
import UIKit

class LicenseListViewController : UIViewController {
    enum Dependency : String, CaseIterable {
        case SnapKit
        case TrustKit
        case ZIPFoundation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        let content = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let title = UILabel(label: "Avoimen lähdekoodin lisenssit", font: .heading2, color: UIColor.Greyscale.black)
        title.numberOfLines = -1
        content.addSubview(title)
        
        title.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        var topAnchor = title.snp.bottom
        
        for dependency in Dependency.allCases {
            let name = UILabel(label: dependency.rawValue, font: .labelPrimary, color: UIColor.Greyscale.black)
            content.addSubview(name)
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            name.addGestureRecognizer(tapRecognizer)
            name.isUserInteractionEnabled = true
            name.accessibilityTraits = .link
            
            name.snp.makeConstraints { make in
                make.top.equalTo(topAnchor).offset(20)
                make.left.right.equalToSuperview()
            }
            
            topAnchor = name.snp.bottom
        }
        
        content.snp.makeConstraints { make in
            make.bottom.equalTo(topAnchor)
        }
    }
    
    @objc
    private func handleTap(sender: UIGestureRecognizer) {
        Log.d("handling tap")
    }
}

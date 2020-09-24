import UIKit

class LicenseViewController: UIViewController {
    let libraryName: String
    
    init(libraryName: String) {
        self.libraryName = libraryName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let content = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        let text = Bundle.main.localizedString(forKey: libraryName, value: nil, table: "Licenses")

        let license = UILabel(label: text, font: .bodySmall, color: UIColor.Greyscale.black)
        license.numberOfLines = -1
        content.addSubview(license)
        
        license.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

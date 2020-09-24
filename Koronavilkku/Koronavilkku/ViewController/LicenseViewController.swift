import UIKit

class LicenseViewController: UIViewController {
    let dependency: LicenseListViewController.Dependency
    
    init(dependency: LicenseListViewController.Dependency) {
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = dependency.rawValue
        
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
        )
        
        let license = UILabel(label: dependency.license,
                              font: .bodySmall,
                              color: UIColor.Greyscale.black)
        
        license.numberOfLines = -1
        content.addSubview(license)
        
        license.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

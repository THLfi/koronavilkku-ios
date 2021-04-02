
import Foundation
import UIKit
import SnapKit

class ExposureLogsViewController: UIViewController {
    
    let logLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        self.view.backgroundColor = UIColor.Greyscale.white
        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        logLabel.numberOfLines = 0
        logLabel.lineBreakMode = .byWordWrapping
        logLabel.text = LocalStore.shared.detectionData
            .map { String(describing: $0) }
            .joined(separator: "\n\n")
        
        scrollView.addSubview(logLabel)
        logLabel.snp.makeConstraints { make in
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
            make.top.bottom.equalToSuperview().offset(20)
        }
        
        Log.d(logLabel.text ?? "") // In case one needs to copy the data elsewhere.
    }
}

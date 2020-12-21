import UIKit

class BaseReportInfectionViewController: UIViewController {
    
    var flowController: ReportInfectionFlowViewController {
        navigationController as! ReportInfectionFlowViewController
    }
    
    var content: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.setHidesBackButton(true, animated: false)
        
        let backButton = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(backHandler))
        backButton.accessibilityLabel = Translation.ButtonBack.localized
        navigationItem.setLeftBarButton(backButton, animated: false)
    }

    internal func createContentWrapper(floatingButton: RoundedButton? = nil) {
        let buttonMargin = UIEdgeInsets(top: 20,
                                        left: 20,
                                        bottom: 30,
                                        right: 20)
        
        let bottomSpacing = floatingButton != nil ? buttonMargin.bottom + RoundedButton.height : 0
        
        let margin = UIEdgeInsets(top: 20,
                                  left: 20,
                                  bottom: 30 + bottomSpacing,
                                  right: 20)
        
        self.content = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop,
                                                     margins: margin)
        
        if let button = floatingButton {
            let fadeBlock = FadeBlock(color: UIColor.Secondary.blueBackdrop)
            view.addSubview(fadeBlock)

            fadeBlock.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }

            view.addSubview(button)
            
            button.snp.makeConstraints { make in
                make.top.left.right.equalTo(fadeBlock).inset(buttonMargin)
                make.bottom.equalTo(view.safeAreaLayoutGuide).inset(buttonMargin)
            }
        }
    }

    @objc
    func backHandler() {
        flowController.navigateBack()
    }
}

import UIKit

class BaseReportInfectionViewController: UIViewController {
    
    var flowController: ReportInfectionFlowViewController {
        navigationController as! ReportInfectionFlowViewController
    }
    
    var content: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = nil
        navigationItem.largeTitleDisplayMode = .never

        // show back arrow when in the root view, as this flow is shown modally
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(close))
            navigationItem.leftBarButtonItem?.accessibilityLabel = Translation.ButtonBack.localized
        }
    }

    internal func createContentWrapper(floatingButton: RoundedButton? = nil) {
        let buttonMargin = UIEdgeInsets(top: 20,
                                        left: 20,
                                        bottom: 44,
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
                make.bottom.equalTo(view.safeAreaLayoutGuide)
                make.left.right.equalToSuperview()
            }

            view.addSubview(button)
            
            button.snp.makeConstraints { make in
                make.edges.equalTo(fadeBlock).inset(buttonMargin)
            }
        }
    }

    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

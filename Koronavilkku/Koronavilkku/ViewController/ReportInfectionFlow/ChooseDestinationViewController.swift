import UIKit

class ChooseDestinationViewController: UIViewController {
    
    enum Text: String, Localizable {
        case Title
        case DestinationEFGS
        case DestinationLocal
    }
    
    private var radioButtonGroup: RadioButtonGroup<ReportingDestination>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem?.accessibilityLabel = Translation.ButtonBack.localized

        let container = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop,
                                                      margins: UIEdgeInsets(left: 20, right: 20))
        
        let titleView = UILabel(label: Text.Title.localized, font: .heading3, color: UIColor.Greyscale.black)
        titleView.numberOfLines = 0
        
        let radioEFGS = RadioButton(value: ReportingDestination.efgs,
                                    label: Text.DestinationEFGS.localized)
        
        let radioLocalOnly = RadioButton(value: ReportingDestination.local,
                                         label: Text.DestinationLocal.localized)
        
        self.radioButtonGroup = RadioButtonGroup([radioEFGS, radioLocalOnly])
        
        container.layout { append in
            append(titleView, nil)
            append(radioEFGS.embedInCard(), UIEdgeInsets(top: 20))
            append(radioLocalOnly.embedInCard(), UIEdgeInsets(top: 20))
        }

        radioButtonGroup.onChange { [unowned self] value in
//            (self.navigationController as? ReportInfectionFlowViewController).setReportingDestination(value)
        }
    }

    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

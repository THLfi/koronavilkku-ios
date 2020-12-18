import Combine
import UIKit

class ChooseDestinationViewController: BaseReportInfectionViewController {
    
    enum Text: String, Localizable {
        case Title
        case DestinationEFGS
        case DestinationLocal
        case PublishTokenReceived
    }
    
    private var radioButtonGroup: RadioButtonGroup<ReportingDestination>!
    private var updateTask: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let continueButton = RoundedButton(title: Translation.ButtonNext.localized) { [unowned self] in
            guard let destination = radioButtonGroup.value else { return }
            self.flowController.setDestination(destination: destination)
        }
        
        continueButton.setEnabled(false)
        createContentWrapper(floatingButton: continueButton)

        let titleLabel = UILabel(label: Text.Title.localized,
                                font: .heading3,
                                color: UIColor.Greyscale.black)
        
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        
        let radioEFGS = RadioButton(value: ReportingDestination.efgs,
                                    label: Text.DestinationEFGS.localized)
        
        let radioLocal = RadioButton(value: ReportingDestination.local,
                                         label: Text.DestinationLocal.localized)
        
        self.radioButtonGroup = RadioButtonGroup([radioEFGS, radioLocal])
        
        let hasTokenLabel = UILabel.init(label: Text.PublishTokenReceived.localized,
                                          font: .bodySmall,
                                          color: UIColor.Greyscale.darkGrey)
        
        hasTokenLabel.numberOfLines = 0
        hasTokenLabel.textAlignment = .center
        
        content.layout { append in
            append(titleLabel, nil)
            append(CardElement(embed: radioEFGS), UIEdgeInsets(top: 20))
            append(CardElement(embed: radioLocal), UIEdgeInsets(top: 20))
            append(hasTokenLabel, UIEdgeInsets(top: 40))
        }

        radioButtonGroup.onChange { _ in
            continueButton.setEnabled(true)
        }
        
        self.updateTask = flowController.$viewModel.sink { viewModel in
            hasTokenLabel.isHidden = !viewModel.tokenReceived
        }
    }
}

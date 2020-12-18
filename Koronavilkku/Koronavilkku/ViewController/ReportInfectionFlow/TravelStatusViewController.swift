import UIKit

class TravelStatusViewController: BaseReportInfectionViewController {
    
    enum Text: String, Localizable {
        case Title
        case NotTravelled
        case HasTravelled
    }
    
    private var radioButtonGroup: RadioButtonGroup<Bool>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let continueButton = RoundedButton(title: Translation.ButtonContinue.localized) { [unowned self] in
            guard let hasTravelled = radioButtonGroup.value else { return }
            self.flowController.setTravelStatus(hasTravelled: hasTravelled)
        }
        
        continueButton.setEnabled(false)
        createContentWrapper(floatingButton: continueButton)

        let titleLabel = UILabel(label: Text.Title.localized,
                                font: .heading3,
                                color: UIColor.Greyscale.black)
        
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        let radioNotTravelled = RadioButton(value: false,
                                            label: Text.NotTravelled.localized)
        
        let radioHasTravelled = RadioButton(value: true,
                                            label: Text.HasTravelled.localized)
        
        self.radioButtonGroup = RadioButtonGroup([radioNotTravelled, radioHasTravelled])
        
        content.layout { append in
            append(titleLabel, nil)
            append(CardElement(embed: radioNotTravelled), UIEdgeInsets(top: 20))
            append(CardElement(embed: radioHasTravelled), UIEdgeInsets(top: 20))
        }

        radioButtonGroup.onChange { _ in
            continueButton.setEnabled(true)
        }

        if let travelStatus = flowController.viewModel.travelStatus {
            self.radioButtonGroup.value = travelStatus.hasTravelled
        }
    }
}

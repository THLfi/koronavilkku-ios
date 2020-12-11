import UIKit

class ConfirmReportViewController: BaseReportInfectionViewController {
    
    enum Text: String, Localizable {
        case Title
        case MessageLocal
        case MessageEFGS
        case TravelSubtitle
        case NotTravelledMessage
        case HasTravelledMessage
        case OptionOther
        case TermsSubtitle
        case TermsCheckboxLocal
        case TermsCheckboxEFGS
        case TermsDisclaimer
        case Button
    }
    
    private var acceptedTerms = [ReportingDestination: Bool]()
    private var button: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createContentWrapper()

        let titleLabel = UILabel(label: Text.Title.localized, font: .heading2, color: UIColor.Greyscale.black)
        titleLabel.numberOfLines = 0
        
        let messageLabel = UILabel(label: getMessage().localized, font: .bodySmall, color: UIColor.Greyscale.black)
        messageLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel(label: Text.TermsSubtitle.localized, font: .heading4, color: UIColor.Greyscale.black)
        subtitleLabel.numberOfLines = 0
        
        let disclaimerLabel = UILabel(label: Text.TermsDisclaimer.localized, font: .bodySmall, color: UIColor.Greyscale.darkGrey)
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.textAlignment = .center
        
        self.button = RoundedButton(title: Text.Button.localized) { [unowned self] in
            self.flowController.acceptTerms()
        }
        
        button.setEnabled(false)
        
        content.layout { append in
            append(titleLabel, nil)
            append(messageLabel, UIEdgeInsets(top: 10))

            if let travelStatus = flowController.viewModel.travelStatus {
                append(createTravelStatusView(status: travelStatus), UIEdgeInsets(top: 20))
            }
            
            append(subtitleLabel, UIEdgeInsets(top: 20))
            append(createAgreementCheckbox(destination: .local), UIEdgeInsets(top: 10))
            
            if case .efgs = flowController.viewModel.destination {
                append(createAgreementCheckbox(destination: .efgs), UIEdgeInsets(top: 20))
            }
            
            append(disclaimerLabel, UIEdgeInsets(top: 20))
            append(button, UIEdgeInsets(top: 20))
        }
    }
    
    private func getMessage() -> Text {
        switch flowController.viewModel.destination! {
        case .efgs:
            return .MessageEFGS
            
        case .local:
            return .MessageLocal
        }

    }
    
    private func createTravelStatusView(status: TravelStatus) -> UIView {
        let subtitleLabel = UILabel(label: Text.TravelSubtitle.localized, font: .heading4, color: UIColor.Greyscale.black)
        subtitleLabel.numberOfLines = 0
        
        let message: Text = status.hasTravelled ? .HasTravelledMessage : .NotTravelledMessage
        let messageLabel = UILabel(label: message.localized, font: .bodySmall, color: UIColor.Greyscale.black)
        messageLabel.numberOfLines = 0
        
        let countries = status.travelledCountries.map {
            $0.localizedName
        }.sorted()
        
        return UIView().layout { append in
            append(subtitleLabel, nil)
            append(messageLabel, UIEdgeInsets(top: 10))
            
            for country in countries {
                append(BulletItem(text: country, textColor: UIColor.Greyscale.darkGrey), UIEdgeInsets(top: 10))
            }
            
            if status.otherCountries {
                append(BulletItem(text: Text.OptionOther.localized, textColor: UIColor.Greyscale.darkGrey), UIEdgeInsets(top: 10))
            }
        }
    }
    
    private func createAgreementCheckbox(destination: ReportingDestination) -> UIView {
        let label: Text
        
        switch destination {
        case .efgs:
            label = .TermsCheckboxEFGS
        case .local:
            label = .TermsCheckboxLocal
        }
        
        self.acceptedTerms[destination] = false

        let checkbox = Checkbox(label: label.localized) { [unowned self] isChecked in
            self.acceptedTerms[destination] = isChecked
            self.updateButtonState()
        }
        
        return CardElement(embed: checkbox)
    }
    
    private func updateButtonState() {
        button.setEnabled(self.acceptedTerms.allSatisfy { $1 })
    }
}

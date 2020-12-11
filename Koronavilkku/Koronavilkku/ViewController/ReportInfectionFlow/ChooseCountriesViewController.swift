import UIKit

class ChooseCountriesViewController: BaseReportInfectionViewController {
    
    enum Text: String, Localizable {
        case Title
        case Message
        case CheckboxOther
    }
    
    let countryList: Set<EFGSCountry>
    var selectedCountries = Set<EFGSCountry>()
    
    init(countries: Set<EFGSCountry>) {
        self.countryList = countries
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createContentWrapper()
        
        title = Text.Title.localized
        
        let messageLabel = UILabel(label: Text.Message.localized,
                                   font: .bodyLarge,
                                   color: UIColor.Greyscale.black)
        
        messageLabel.numberOfLines = 0
        
        let button = RoundedButton(title: Translation.ButtonNext.localized) { [unowned self] in
            flowController.setTravelStatus(countries: selectedCountries)
        }
        
        let countries = Dictionary.init(grouping: countryList) {
            String($0.localizedName.first ?? Character(""))
        }.sorted { $0.key < $1.key }
        
        let otherCheckbox = Checkbox(label: Text.CheckboxOther.localized) { _ in }
        
        content.layout { append in
            append(messageLabel, nil)
            
            for (letter, countries) in countries {
                append(UILabel(label: String(letter), font: .heading5, color: UIColor.Greyscale.darkGrey), UIEdgeInsets(top: 20))

                for country in countries {
                    append(createCheckbox(for: country), UIEdgeInsets(top: 10))
                }
            }
            
            append(UIView.createDivider(height: 1), UIEdgeInsets(top: 30, bottom: 30))
            append(CardElement(embed: otherCheckbox), nil)
            append(button, UIEdgeInsets(top: 60))
        }
    }
    
    private func createCheckbox (for country: EFGSCountry) -> UIView {
        let checkbox = Checkbox(label: country.localizedName) { [unowned self] isChecked in
            if isChecked {
                self.selectedCountries.insert(country)
            } else {
                self.selectedCountries.remove(country)
            }
        }
        
        return CardElement(embed: checkbox)
    }
}

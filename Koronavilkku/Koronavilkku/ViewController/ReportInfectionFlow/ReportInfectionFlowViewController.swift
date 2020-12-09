import UIKit

enum ReportingDestination {
    case local
    case efgs
}

struct TravelStatus {
    let hasTravelled: Bool?
    let travelledCountries = [EFGSCountry]()
    let otherCountries = false
}

struct ReportInfectionViewModel {
    let destination: ReportingDestination?
    let travelStatus: TravelStatus?
    let publishToken: String?
}

class ReportInfectionFlowViewController: UINavigationController {
    
    @Published
    private(set) var viewModel: ReportInfectionViewModel
    
    init(publishToken: String? = nil) {
        self.viewModel = .init(destination: nil, travelStatus: nil, publishToken: publishToken)
        super.init(rootViewController: ChooseDestinationViewController())

        modalPresentationStyle = .fullScreen
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.Secondary.blueBackdrop
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont.labelPrimary,
            .foregroundColor: UIColor.Greyscale.black
        ]
        
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .font: UIFont.labelPrimary,
        ]

        appearance.buttonAppearance = buttonAppearance
        
        navigationBar.standardAppearance = appearance
        navigationBar.tintColor = UIColor.Primary.blue
    }
    
    func setPublishToken(publishToken: String) {
        viewModel = .init(destination: viewModel.destination,
                          travelStatus: viewModel.travelStatus,
                          publishToken: publishToken)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

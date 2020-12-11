import UIKit

enum ReportingDestination {
    case local
    case efgs
}

struct TravelStatus {
    let hasTravelled: Bool
    let travelledCountries: Set<EFGSCountry>
    let otherCountries: Bool
}

struct ReportInfectionViewModel {
    let destination: ReportingDestination?
    let travelStatus: TravelStatus?
    let publishToken: String?
    let tokenReceived: Bool
}

class ReportInfectionFlowViewController: UINavigationController {
    
    @Published
    private(set) var viewModel: ReportInfectionViewModel
    
    private let efgsRepository: EFGSRepository
    
    init(efgsRepository: EFGSRepository = Environment.default.efgsRepository, publishToken: String? = nil) {
        self.efgsRepository = efgsRepository
        self.viewModel = .init(destination: nil,
                               travelStatus: nil,
                               publishToken: publishToken,
                               tokenReceived: publishToken != nil)
        
        super.init(rootViewController: ChooseDestinationViewController())
        
        modalPresentationStyle = .fullScreen
        setDefaultStyle()
    }
    
    func setPublishToken(publishToken: String, receivedFromSMS: Bool) {
        viewModel = .init(destination: viewModel.destination,
                          travelStatus: viewModel.travelStatus,
                          publishToken: publishToken,
                          tokenReceived: receivedFromSMS)
    }
    
    func setDestination(destination: ReportingDestination) {
        let travelStatus: TravelStatus?
        let nextVC: BaseReportInfectionViewController
        
        switch destination {
        case .local:
            travelStatus = nil
            nextVC = ConfirmReportViewController()
        default:
            travelStatus = viewModel.travelStatus
            nextVC = TravelStatusViewController()
        }
        
        viewModel = .init(destination: destination,
                          travelStatus: travelStatus,
                          publishToken: viewModel.publishToken,
                          tokenReceived: viewModel.tokenReceived)
        
        pushViewController(nextVC, animated: true)
    }
    
    func setTravelStatus(hasTravelled: Bool) {
        let travelledCountries: Set<EFGSCountry>
        let otherCountries: Bool
        let nextVC: BaseReportInfectionViewController
        
        switch hasTravelled {
        case true:
            travelledCountries = viewModel.travelStatus?.travelledCountries ?? Set()
            otherCountries = viewModel.travelStatus?.otherCountries ?? false
            nextVC = ChooseCountriesViewController(countries: efgsRepository.getParticipatingCountries() ?? [])
            
        case false:
            travelledCountries = []
            otherCountries = false
            nextVC = ConfirmReportViewController()
        }
        
        viewModel = .init(destination: viewModel.destination,
                          travelStatus: TravelStatus(hasTravelled: hasTravelled,
                                                     travelledCountries: travelledCountries,
                                                     otherCountries: otherCountries),
                          publishToken: viewModel.publishToken,
                          tokenReceived: viewModel.tokenReceived)
        
        pushViewController(nextVC, animated: true)
    }
    
    func setTravelStatus(countries: Set<EFGSCountry>, otherCountries: Bool) {
        viewModel = .init(destination: viewModel.destination,
                          travelStatus: TravelStatus(hasTravelled: true,
                                                     travelledCountries: countries,
                                                     otherCountries: countries.isEmpty ? true : otherCountries),
                          publishToken: viewModel.publishToken,
                          tokenReceived: viewModel.tokenReceived)
        
        pushViewController(ConfirmReportViewController(), animated: true)
    }
    
    func acceptTerms() {
        pushViewController(PublishTokensViewController(), animated: true)
    }
    
    func navigateBack() {
        if viewControllers.count > 1 {
            popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

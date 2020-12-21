import Combine
import ExposureNotification
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
    
    var shareWithEFGS: Bool {
        switch destination {
        case .efgs:
            return true
        
        default:
            return false
        }
    }
}

class ReportInfectionFlowViewController: UINavigationController {
    
    enum Text: String, Localizable {
        case FinishedTitle
        case FinishedText
        case FinishedButton
    }
    
    @Published
    private(set) var viewModel: ReportInfectionViewModel
    
    private lazy var allCountries: Set<EFGSCountry> = efgsRepository.getParticipatingCountries() ?? Set()
    
    private let efgsRepository: EFGSRepository
    private let exposureRepository: ExposureRepository
    private var tasks = Set<AnyCancellable>()
    
    init(efgsRepository: EFGSRepository = Environment.default.efgsRepository,
         exposureRepository: ExposureRepository = Environment.default.exposureRepository,
         publishToken: String? = nil) {
        
        self.efgsRepository = efgsRepository
        self.exposureRepository = exposureRepository
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

        case .efgs:
            travelStatus = viewModel.travelStatus

            // if the country list is missing, skip the travel status and country selection
            nextVC = allCountries.isEmpty
                ? ConfirmReportViewController()
                : TravelStatusViewController()
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
            nextVC = ChooseCountriesViewController(countries: allCountries)
            
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
    
    func submit(publishToken: String?) {
        viewModel = .init(destination: viewModel.destination,
                          travelStatus: viewModel.travelStatus,
                          publishToken: publishToken,
                          tokenReceived: viewModel.tokenReceived)
        
        exposureRepository.postExposureKeys(publishToken: viewModel.publishToken,
                                            visitedCountries: viewModel.travelStatus?.travelledCountries ?? Set(),
                                            shareWithEFGS: viewModel.shareWithEFGS)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] in
                    guard let self = self,
                          let viewController = self.topViewController as? PublishTokensViewController else { return }
                    
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    switch $0 {
                    case .failure(let error as NSError):
                        feedbackGenerator.notificationOccurred(.error)
                        Log.e("Failed to post exposure keys: \(error)")
                        viewController.failure = error

                    case .finished:
                        feedbackGenerator.notificationOccurred(.success)
                        self.showFinishViewController()
                    }
                },
                receiveValue: {}
            )
            .store(in: &tasks)
    }
    
    private func showFinishViewController() {
        let finishViewController = InfoViewController()
        finishViewController.image = UIImage(named: "ok")
        finishViewController.titleText = Text.FinishedTitle.localized
        finishViewController.textLabelText = Text.FinishedText.localized
        finishViewController.buttonTitle = Text.FinishedButton.localized
        finishViewController.buttonPressed = { [unowned finishViewController] in
            UIApplication.shared.selectRootTab(.home)
            finishViewController.dismiss(animated: true, completion: nil)
        }
        
        self.pushViewController(finishViewController, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSError {
    func equals(_ code: ENError.Code) -> Bool {
        return domain == ENErrorDomain && self.code == code.rawValue
    }
}


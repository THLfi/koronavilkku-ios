#if DEBUG

import Combine
import ExposureNotification
import SwiftUI

enum PreviewError: Error {
    case notSupported
}

private struct UIViewControllerPreviewContainer<T: UIViewController> : UIViewControllerRepresentable {
    var viewController: T
    
    func makeUIViewController(context: Context) -> T {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: T, context: Context) {
    }
}

private struct UIViewPreviewContainer<T: UIView> : UIViewRepresentable {
    var view: T
    
    func makeUIView(context: Context) -> T {
        return view
    }
    
    func updateUIView(_ uiView: T, context: Context) {
    }
}

struct PreviewState {
    var detectionStatus = Just<DetectionStatus>(.init(status: .on, delayed: false, running: false))
    var exposureStatus = Just<ExposureStatus>(.unexposed)
    var timeFromLastCheck = Just<TimeInterval?>(TimeInterval(-360))
    var exposureNotifications = Just<[ExposureNotification]>(.init())
}

extension Environment {
    static func preview(createState: @escaping () -> PreviewState) -> Environment {
        struct PreviewConfiguration: Configuration {
            var apiBaseURL = ""
            var cmsBaseURL = ""
            var omaoloBaseURL = ""
            var trustKit: TrustKitConfiguration? = nil
            var version = "SwiftUI Preview"
        }

        struct PreviewExposureRepository: ExposureRepository {
            func isEndOfLife() -> Bool {
                return false
            }
            
            let state: PreviewState
            
            func getExposureNotifications() -> AnyPublisher<[ExposureNotification], Never> {
                state.exposureNotifications.eraseToAnyPublisher()
            }

            func detectionStatus() -> AnyPublisher<DetectionStatus, Never> {
                state.detectionStatus.eraseToAnyPublisher()
            }
            
            func exposureStatus() -> AnyPublisher<ExposureStatus, Never> {
                state.exposureStatus.eraseToAnyPublisher()
            }
            
            func timeFromLastCheck() -> AnyPublisher<TimeInterval?, Never> {
                state.timeFromLastCheck.eraseToAnyPublisher()
            }
            
            func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func postExposureKeys(publishToken: String?, visitedCountries: Set<EFGSCountry>, shareWithEFGS: Bool) -> AnyPublisher<Void, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func postDummyKeys() -> AnyPublisher<Void, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func refreshStatus() {
            }
            
            func setStatus(enabled: Bool) {
            }
            
            func tryEnable(_ completionHandler: @escaping (ENError.Code?) -> Void) {
                completionHandler(nil)
            }
            
            func deleteBatchFiles() {
            }
            
            func removeExpiredExposures() {
            }
            
            func showExposureNotification(delay: TimeInterval?) {
            }
        }

        struct PreviewBatchRepository: BatchRepository {
            func getNewBatches() -> AnyPublisher<String, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func getCurrentBatchId() -> AnyPublisher<String, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
        }

        struct PreviewMunicipalityRepository: MunicipalityRepository {
            var omaoloBaseURL = ""
            
            func updateMunicipalityList() -> AnyPublisher<Void, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
            
            func getMunicipalityList() -> AnyPublisher<Municipalities, Error> {
                return Fail(error: PreviewError.notSupported).eraseToAnyPublisher()
            }
        }
        
        struct PreviewEFGSRepository: EFGSRepository {
            let state: PreviewState

            func getParticipatingCountries() -> Set<EFGSCountry>? {
                Set()
            }

            func updateCountryList(from: ExposureConfiguration) {
            }
        }
        
        struct PreviewNotificationService: NotificationService {
            var enabled = true
            
            func isEnabled(completion: @escaping StatusCallback) {
                completion(enabled)
            }

            func requestAuthorization(provisional: Bool, completion: StatusCallback?) {
            }
            
            func showNotification(title: String, body: String, delay: TimeInterval?, badgeNumber: Int?) {
            }

            func updateBadgeNumber(_ number: Int?) {
            }
        }
        
        let state = createState()
        
        return Environment(configuration: PreviewConfiguration(),
                           batchRepository: PreviewBatchRepository(),
                           efgsRepository: PreviewEFGSRepository(state: state),
                           exposureRepository: PreviewExposureRepository(state: state),
                           municipalityRepository: PreviewMunicipalityRepository(),
                           notificationService: PreviewNotificationService())
    }
}

extension PreviewProvider {
    static func createPreview(for viewController: UIViewController) -> some View {
        UIViewControllerPreviewContainer(viewController: viewController)
            .previewDevice(PreviewDevice("iPhone 11 Pro"))
            .edgesIgnoringSafeArea(.all)
    }
    
    static func createPreviewInNavController(for viewController: UIViewController) -> some View {
        let navController = CustomNavigationController(rootViewController: viewController)
        navController.setDefaultStyle()
        return createPreview(for: navController)
    }
    
    static func createPreview(for view: UIView, width: CGFloat, height: CGFloat) -> some View {
        UIViewPreviewContainer(view: view)
            .previewLayout(.fixed(width: width, height: height))
    }
    
    static func createPreviewInContainer(for view: UIView, width: CGFloat, height: CGFloat) -> some View {
        let container = UIView()
        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(20)
        }
        
        return UIViewPreviewContainer(view: container)
            .previewLayout(.fixed(width: width, height: height))
    }
}

#endif

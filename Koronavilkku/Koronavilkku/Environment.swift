import ExposureNotification
import Foundation
import TrustKit

struct Environment {
    let configuration: Configuration
    let batchRepository: BatchRepository
    let efgsRepository: EFGSRepository
    let exposureRepository: ExposureRepository
    let municipalityRepository: MunicipalityRepository
    let notificationService: NotificationService

    static var `default` = Environment.create()
}

extension Environment {
    static func create() -> Environment {
        let config = LocalConfiguration()
        let urlSession = configureUrlSession(config: config)
        let backend = BackendRestApi(config: config, urlSession: urlSession)
        let cms = CMS(config: config, urlSession: urlSession)
        let storage = FileStorageImpl()
        
        let batchRepository = BatchRepositoryImpl(backend: backend,
                                                  cache: LocalStore.shared,
                                                  storage: storage)
        
        let efgsRepository = EFGSRepositoryImpl(storage: storage)
        let notificationService = NotificationServiceImpl()

        let exposureRepository = ExposureRepositoryImpl(efgsRepository: efgsRepository,
                                                        exposureManager: ExposureManagerProvider.shared.manager,
                                                        notificationService: notificationService,
                                                        backend: backend,
                                                        storage: storage)
        
        let municipalityRepository = MunicipalityRepositoryImpl(cms: cms,
                                                                omaoloBaseURL: config.omaoloBaseURL,
                                                                storage: storage)
        
        return Environment(configuration: config,
                           batchRepository: batchRepository,
                           efgsRepository: efgsRepository,
                           exposureRepository: exposureRepository,
                           municipalityRepository: municipalityRepository,
                           notificationService: notificationService)
    }
    
    static func configureUrlSession(config: Configuration) -> URLSession {
        let delegate: URLSessionDelegate?

        TrustKit.setLoggerBlock(Log.d)

        if let tskConfig = config.trustKit {
            TrustKit.initSharedInstance(withConfiguration: tskConfig)
            delegate = URLSession.pinningDelegate
        } else {
            delegate = nil
        }

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpCookieAcceptPolicy = .never
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieStorage = nil
        
        return URLSession(configuration: sessionConfiguration,
                          delegate: delegate,
                          delegateQueue: nil)
    }
}

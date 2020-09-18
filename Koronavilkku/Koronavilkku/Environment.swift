import ExposureNotification
import Foundation
import TrustKit

struct Environment {
    let configuration: Configuration
    let batchRepository: BatchRepository
    let exposureRepository: ExposureRepository
    let municipalityRepository: MunicipalityRepository

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
        
        let exposureRepository = ExposureRepositoryImpl(exposureManager: ExposureManagerProvider.shared.manager,
                                                        backend: backend,
                                                        storage: storage)
        
        let municipalityRepository = MunicipalityRepositoryImpl(cms: cms,
                                                                omaoloBaseURL: config.omaoloBaseURL,
                                                                storage: storage)
        
        return Environment(configuration: config,
                           batchRepository: batchRepository,
                           exposureRepository: exposureRepository,
                           municipalityRepository: municipalityRepository)
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

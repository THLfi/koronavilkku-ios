import Combine
import ExposureNotification
import Foundation

protocol ExposureManager {
    var exposureNotificationStatus: ENStatus { get }
    func activate(completionHandler: @escaping ENErrorHandler)
    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> AnyPublisher<ENExposureDetectionSummary, Error>
    func getExposureInfo(summary: ENExposureDetectionSummary, userExplanation: String) -> AnyPublisher<[ENExposureInfo], Error>
    func getDiagnosisKeys() -> AnyPublisher<[ENTemporaryExposureKey], Error>
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ENErrorHandler)
    func invalidate()
}

enum ExposureManagerError : Error {
    case unknown
}

class ExposureManagerProvider {
    static var shared = ExposureManagerProvider()
    
    let manager: ExposureManager
    let activated: AnyPublisher<Bool, Never>
    
    private init() {
        #if targetEnvironment(simulator)
        let manager = MockExposureManager()
        #else
        let manager = ENManager()
        #endif

        activated = Future { promise in
            manager.activate { error in
                
                if let error = error {
                    Log.e("Unable to activate ExposureManager, error: \(error)")
                    promise(.success(false))
                } else {
                    promise(.success(true))
                    Log.d("Authorization status: \(ENManager.authorizationStatus.rawValue) ")
                }
            }
        }.setFailureType(to: Never.self).eraseToAnyPublisher()
        
        self.manager = manager
    }
    
    deinit {
        manager.invalidate()
    }
}

extension ENManager : ExposureManager {
    
    func getDiagnosisKeys() -> AnyPublisher<[ENTemporaryExposureKey], Error> {
        Future { promise in
            let completion: ENGetDiagnosisKeysHandler = { (keys, error) in
                if let keys = keys {
                    promise(.success(keys))
                } else {
                    promise(.failure(error ?? ExposureManagerError.unknown))
                }
            }
            
            #if DEBUG
            self.getTestDiagnosisKeys(completionHandler: completion)
            #else
            self.getDiagnosisKeys(completionHandler: completion)
            #endif
        }.eraseToAnyPublisher()
    }
    
    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> AnyPublisher<ENExposureDetectionSummary, Error> {
        Future { promise in
            let configuration = ENExposureConfiguration(from: configuration)
            Log.d("Detect exposures with configuration: \(configuration)")
            let _ = self.detectExposures(configuration: configuration, diagnosisKeyURLs: diagnosisKeyURLs) { summary, error in
                if let summary = summary {
                    promise(.success(summary))
                } else {
                    promise(.failure(error ?? NSError(domain: "fi.thl.koronahaavi", code: 0, userInfo: nil)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getExposureInfo(summary: ENExposureDetectionSummary, userExplanation: String) -> AnyPublisher<[ENExposureInfo], Error> {
        Future { promise in
            let _ = self.getExposureInfo(summary: summary, userExplanation: userExplanation) { info, error in
                if let info = info {
                    promise(.success(info))
                } else {
                    promise(.failure(error ?? NSError(domain: "fi.thl.koronahaavi", code: 0, userInfo: nil)))
                }
            }
        }.eraseToAnyPublisher()
    }
}

class MockExposureManager : ExposureManager {
    var systemDisabled: Bool = false {
        didSet {
            exposureNotificationStatus = systemDisabled ? .restricted : .active
        }
    }
    
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ENErrorHandler) {
        if systemDisabled {
            return completionHandler(NSError(domain: "fi.thl.koronahaavi", code: ENStatus.restricted.rawValue))
        }
        
        exposureNotificationStatus = enabled ? ENStatus.active : ENStatus.disabled
        completionHandler(nil)
    }
    
    var exposureNotificationStatus = ENStatus.active
    
    func getDiagnosisKeys() -> AnyPublisher<[ENTemporaryExposureKey], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func detectExposures(configuration: ExposureConfiguration, diagnosisKeyURLs: [URL]) -> AnyPublisher<ENExposureDetectionSummary, Error> {
        var summary = ENExposureDetectionSummary()
        #if targetEnvironment(simulator)
        summary = MockENExposureDetectionSummary()
        #endif
        LocalStore.shared.updateDateLastPerformedExposureDetection()
        return Just(summary).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func activate(completionHandler: @escaping ENErrorHandler) {
        completionHandler(nil)
    }
    
    func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler) {
    }
    
    func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler) {
    }
    
    func getExposureInfo(summary: ENExposureDetectionSummary, userExplanation: String) -> AnyPublisher<[ENExposureInfo], Error> {
        return Just([ENExposureInfo()]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func invalidate() {
    }
}

#if targetEnvironment(simulator)
class MockENExposureDetectionSummary: ENExposureDetectionSummary {
    override var matchedKeyCount: UInt64 {
        get { UInt64(1) }
    }
}
#endif

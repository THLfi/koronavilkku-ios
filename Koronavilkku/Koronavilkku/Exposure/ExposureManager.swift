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
    
    enum MockExposureManagerError: Error {
        case MissingTimezone
    }
    
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
    
    /**
     * Return Temporary Exposure Keys for the last 14 days
     *
     * The implementation should reflect the modern EN API where the same-day key is also given
     * but the TEK rolling period is capped to the current moment
     */
    func getDiagnosisKeys() -> AnyPublisher<[ENTemporaryExposureKey], Error> {
        guard let tz = TimeZone.init(identifier: "UTC") else {
            return Fail(error: MockExposureManagerError.MissingTimezone).eraseToAnyPublisher()
        }
        
        var cal = Calendar.init(identifier: .gregorian)
        cal.timeZone = tz
        let today = Date()
        let numberOfDays = 14

        return Just((0..<numberOfDays).compactMap { index in
            guard let datetime = cal.date(byAdding: .day, value: 1 - numberOfDays + index, to: today),
                let date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: datetime),
                let data = Data(base64Encoded: TemporaryExposureKey.randomData(ofLength: 16))
                else {
                    return nil
            }
            
            let rollingPeriod = today.timeIntervalSince(date) / 600
            let tek = ENTemporaryExposureKey()
            tek.keyData = data
            tek.rollingPeriod = rollingPeriod < 144 ? ENIntervalNumber(rollingPeriod) : 144
            tek.rollingStartNumber = ENIntervalNumber(date.timeIntervalSince1970 / 600)
            tek.transmissionRiskLevel = 0

            Log.d("Generated TEK with rolling start number \(tek.rollingStartNumber) and period \(tek.rollingPeriod)")
            return tek
        }).setFailureType(to: Error.self).eraseToAnyPublisher()
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

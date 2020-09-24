import Combine
import ExposureNotification
import Foundation
import Dispatch

protocol ExposureRepository {
    func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error>
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error>
    func postExposureKeys(publishToken: String?) -> AnyPublisher<Void, Error>
    func postDummyKeys() -> AnyPublisher<Void, Error>
    func refreshStatus()
    func setStatus(enabled: Bool)
    func tryEnable(_ completionHandler: @escaping (ENError.Code?) -> Void)
    func deleteBatchFiles()
}

struct ExposureRepositoryImpl : ExposureRepository {
    static let keyCount = 14
    private static let dummyPostToken = "000000000000"
    private let exposureManager: ExposureManager
    private let backend: Backend
    private let storage: FileStorage
    
    init(exposureManager: ExposureManager, backend: Backend, storage: FileStorage) {
        self.exposureManager = exposureManager
        self.backend = backend
        self.storage = storage
    }
    
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
        return backend.getConfiguration()
    }
    
    func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error> {
        
        #if DEBUG
        // If exposureInfo.score < minimumRiskScore, then the score and other values will be 0.
        // To get more information about those cases use the minimum allowed value.
        let cfg = config.with(minimumRiskScore: 1)
        #else
        let cfg = config
        #endif
        
        let urls = ids.map { self.storage.getFileUrls(forBatchId: $0) }.flatMap { $0 }
        Log.d("Ids: \(ids), Config: \(config), Detecting with urls: \(urls)")

        return self.exposureManager.detectExposures(configuration: cfg, diagnosisKeyURLs: urls)
            .flatMap { summary -> AnyPublisher<[ENExposureInfo], Error> in
                Log.d("Got summary: \(summary)")
                
                if let latestId = ids.sorted().last {
                    LocalStore.shared.nextDiagnosisKeyFileIndex = latestId
                }
                
                #if DEBUG
                    // When dbugging, store detection summary to local store for debugging purposes
                    LocalStore.shared.detectionSummaries.append(summary.to())
                #endif
                
                // Matched key count is not the one to use to determine real exposures.
                // We must check that Summary's maximumRiskScore >= minimumRiskScore in server configuration
                // and filter results to only those and fetch info for only
                let validDetections = summary.maximumRiskScoreFullRange >= Double(config.minimumRiskScore)
                Log.d("Valid detections? \(validDetections)")
                
                if validDetections && summary.matchedKeyCount > 0 {
                    let userExplanation = Translation.ExposureNotificationUserExplanation.localized
                    return self.exposureManager.getExposureInfo(summary: summary, userExplanation: userExplanation)
                } else {
                    return Just([ENExposureInfo]()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            }
            .map { exposureInfos -> Bool in
                let detectedExposures = exposureInfos.count > 0

                if detectedExposures {
                    let exposures = exposureInfos.map { $0.to() }
                    DispatchQueue.main.async {
                        LocalStore.shared.exposures.append(contentsOf: exposures)
                    }
                }

                return detectedExposures
            }
            .eraseToAnyPublisher()
    }
    
    func deleteBatchFiles() {
        // Since we are only processing 1 batch set at a time, always clean up the entire batches directory.
        storage.deleteAllBatches()
    }
    
    func postExposureKeys(publishToken: String?) -> AnyPublisher<Void, Error> {
        return self.exposureManager.getDiagnosisKeys()
            .flatMap { enTemporaryExposureKeys -> AnyPublisher<Data, Error> in
                let tempKeys = self.mapKeysToCorrectLength(enTemporaryExposureKeys: enTemporaryExposureKeys)
                Log.d("Post \(tempKeys.count) keys")
                return self.backend.postDiagnosisKeys(publishToken: publishToken,
                                                      publishRequest: DiagnosisPublishRequest(keys: tempKeys),
                                                      isDummyRequest: false)
            }
            .map { _ in
                // strip away the response

                DispatchQueue.main.async {
                    LocalStore.shared.uiStatus = .locked
                    self.setStatus(enabled: false)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func postDummyKeys() -> AnyPublisher<Void, Error> {
        // Post 14 dummy keys to backend
        let keys = (0..<ExposureRepositoryImpl.keyCount).map { TemporaryExposureKey.createDummy(index: $0) }
        Log.d("Dummy post \(keys.count) dummy keys")
        return self.backend.postDiagnosisKeys(publishToken: ExposureRepositoryImpl.dummyPostToken,
                                                            publishRequest: DiagnosisPublishRequest(keys: keys),
                                                            isDummyRequest: true)
            .map { _ in
                // strip away the response
            }
            .eraseToAnyPublisher()
    }
    
    func mapKeysToCorrectLength(enTemporaryExposureKeys: [ENTemporaryExposureKey]) -> [TemporaryExposureKey] {
        var keys = enTemporaryExposureKeys.map { $0.toTemporaryExposureKey() }
        // If there are more than 14 keys, remove old keys by sorting temporary keys to descending order
        // by rollingStartIntervalNumber and removing tail from sorted array
        if keys.count > ExposureRepositoryImpl.keyCount {
            keys = Array(keys.sorted(by: { (key1, key2) -> Bool in
                return key1.rollingStartIntervalNumber > key2.rollingStartIntervalNumber
            })
            .prefix(ExposureRepositoryImpl.keyCount))
        }
        
        // pad keys to length of 14
        while keys.count < ExposureRepositoryImpl.keyCount {
            keys.append(TemporaryExposureKey.createDummy(index: 0))
        }
        
        return keys
    }
    
    func refreshStatus() {
        if LocalStore.shared.uiStatus == .locked {
            return
        }
        
        let status: RadarStatus

        if type(of: exposureManager).authorizationStatus != .authorized {
            status = .apiDisabled
        } else {
            status = RadarStatus.init(from: exposureManager.exposureNotificationStatus)
        }
        
        Log.d("Status=\(status)")

        if (LocalStore.shared.uiStatus != status) {
            LocalStore.shared.uiStatus = status
        }
    }
    
    func setStatus(enabled: Bool) {
        Log.d("Set enabled=\(enabled)")
        exposureManager.setExposureNotificationEnabled(enabled) { _ in
            self.refreshStatus()
        }
    }
    
    func tryEnable(_ completionHandler: @escaping (ENError.Code?) -> Void) {
        let status = exposureManager.exposureNotificationStatus
        Log.d("ENStatus=\(status.rawValue)")
        
        exposureManager.setExposureNotificationEnabled(true) { error in
            // TODO: Refresh UI status here before calling completion handler
            if let error = error {
                Log.d("Could not enable exposure notifications: \(error)")
                completionHandler(ENError.Code(rawValue: (error as NSError).code) ?? .unknown)
            } else {
                completionHandler(nil)
            }
        }
    }
}

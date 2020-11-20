import Combine
import ExposureNotification
import Foundation
import UIKit

protocol ExposureRepository {
    func detectionStatus() -> AnyPublisher<DetectionStatus, Never>
    func exposureStatus() -> AnyPublisher<ExposureStatus, Never>
    func timeFromLastCheck() -> AnyPublisher<TimeInterval?, Never>
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
    static let manualCheckThreshold: TimeInterval = 24 * 60 * 60
    
    private static let dummyPostToken = "000000000000"

    /// Publisher logic cached here to avoid every subscriber running it separately
    static private var timeFromLastCheck: AnyPublisher<TimeInterval?, Never> = {
        // Create a timer based on the current exposure detection date
        LocalStore.shared.$dateLastPerformedExposureDetection.$wrappedValue.map { lastCheck -> AnyPublisher<TimeInterval?, Never> in
            guard let lastCheck = lastCheck else {
                return Just(nil).eraseToAnyPublisher()
            }
            
            return Timer
                .publish(every: 60, tolerance: 1, on: .main, in: .default)
                .autoconnect()
                // Timer does not publish the current date until it fires the first time
                // To avoid missing data during the first 60 seconds, merge in the current time
                .merge(with: Just(Date()))
                .map { $0.distance(to: lastCheck) }
                .eraseToAnyPublisher()
        }
        // Cancels the previous timer when the value changes to avoid mixed signals
        .switchToLatest()
        .shareCurrent()
        .eraseToAnyPublisher()
    }()
    
    static private var detectionStatus: AnyPublisher<DetectionStatus, Never> = {
        let isDelayed = Self.timeFromLastCheck.map { interval -> Bool in
            guard let interval = interval else { return false }
            return interval <= 0 - Self.manualCheckThreshold
        }
        
        let isDisabled = LocalStore.shared.$uiStatus.$wrappedValue.map { uiStatus -> Bool in
            switch uiStatus {
            case .apiDisabled, .off:
                return true
            default:
                return false
            }
        }
        
        return BackgroundTaskForNotifications.shared.$detectionRunning
            .combineLatest(isDelayed, isDisabled) { running, delayed, disabled in
                switch true {
                case disabled:
                    return .init(status: .disabled, delayed: delayed)
                case running:
                    return .init(status: .detecting, delayed: delayed)
                default:
                    return .init(status: .idle, delayed: delayed)
                }
            }
            .removeDuplicates()
            .shareCurrent()
            .eraseToAnyPublisher()
    }()

    private let exposureManager: ExposureManager
    private let backend: Backend
    private let storage: FileStorage
        
    func detectionStatus() -> AnyPublisher<DetectionStatus, Never> {
        Self.detectionStatus
    }
        
    func timeFromLastCheck() -> AnyPublisher<TimeInterval?, Never> {
        Self.timeFromLastCheck
    }
    
    func exposureStatus() -> AnyPublisher<ExposureStatus, Never> {
        LocalStore.shared.$exposures.$wrappedValue
            .combineLatest(LocalStore.shared.$exposureNotifications.$wrappedValue)
            .map { exposures, notifications -> ExposureStatus in
                if !notifications.isEmpty {
                    return .exposed(notificationCount: notifications.count)
                }
                
                if !exposures.isEmpty {
                    return .exposed(notificationCount: nil)
                }
                
                return .unexposed
            }.eraseToAnyPublisher()
    }

    init(exposureManager: ExposureManager, backend: Backend, storage: FileStorage) {
        self.exposureManager = exposureManager
        self.backend = backend
        self.storage = storage
    }
    
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
        return backend.getConfiguration()
    }
    
    func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error> {

        let urls = ids.map { self.storage.getFileUrls(forBatchId: $0) }.flatMap { $0 }
        Log.d("Ids: \(ids), Config: \(config), Detecting with urls: \(urls)")

        // iOS calculates attenuation buckets only from exposures equal or greater to minimumRiskScore
        // Override the minimumRiskScore for detection only
        return self.exposureManager.detectExposures(configuration: config.with(minimumRiskScore: 1),
                                                    diagnosisKeyURLs: urls)
            .flatMap { summary -> AnyPublisher<[ENExposureInfo], Error> in
                Log.d("Got summary: \(summary)")
                
                if let latestId = ids.sorted().last {
                    LocalStore.shared.nextDiagnosisKeyFileIndex = latestId
                }
                
                #if DEBUG
                    // When debugging, store detection summary to local store for debugging purposes
                    LocalStore.shared.detectionSummaries.append(summary.to())
                #endif
                
                // Matched key count is not the one to use to determine real exposures.
                // We must check that Summary's maximumRiskScore >= minimumRiskScore in server configuration
                // and filter results to only those and fetch info for only
                var validDetections = summary.maximumRiskScoreFullRange >= Double(config.minimumRiskScore)
                
                // On pre-13.6 EN API doesn't support defining attenuationDurationThresholds so
                // bucket calculation isn't meaningful on those devices.
                if !validDetections, #available(iOS 13.6, *) {
                    // The attenuation score is a time weighted average -> if the same device is near for a
                    // short while and then within range (high attenuation) for a really long time, then the
                    // attenuation value could end up being too small to trigger a risk score based exposure
                    // notification. Multiple short exposures can also trigger an exposure notification when
                    // using bucket calculation.
                    let durations = summary.attenuationDurations.weighted(with: config.durationAtAttenuationWeights)
                    let totalMinutes = durations.sumSecondsAsMinutes()
                    
                    if totalMinutes >= config.exposureRiskDuration {
                        Log.d("Long duration exposure detected (\(totalMinutes))")
                        validDetections = true
                    }
                }
                
                Log.d("Valid detections? \(validDetections)")
                
                if validDetections && summary.matchedKeyCount > 0 {
                    let userExplanation = Translation.ExposureNotificationUserExplanation.localized
                    return self.exposureManager.getExposureInfo(summary: summary, userExplanation: userExplanation)
                } else {
                    return Just([ENExposureInfo]()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            }
            .receive(on: RunLoop.main)
            .map { exposureInfos -> Bool in
                guard !exposureInfos.isEmpty else { return false }
                
                exposureInfos.forEach { Log.d("ExposureInfo: \($0)") }
                let notification = exposureInfos.to(config: config)
                LocalStore.shared.exposureNotifications.append(notification)
                return true
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

extension Array where Element == NSNumber {

    func weighted(with weights: [Double]) -> [Double] {
        return self.enumerated().map { (index, duration) in
            let weight = index < weights.count ? weights[index] : 0.0
            return duration.doubleValue * weight
        }
    }
}

extension Array where Element == Double {
    
    func sumSecondsAsMinutes() -> Int {
        return Int(self.reduce(0, +) / 60.0)
    }
}

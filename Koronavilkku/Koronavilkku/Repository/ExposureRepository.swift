import Combine
import ExposureNotification
import Foundation
import UIKit

protocol ExposureRepository {
    func detectionStatus() -> AnyPublisher<DetectionStatus, Never>
    func exposureStatus() -> AnyPublisher<ExposureStatus, Never>
    func getExposureNotifications() -> AnyPublisher<[ExposureNotification], Never>
    func timeFromLastCheck() -> AnyPublisher<TimeInterval?, Never>
    func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error>
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error>
    func postExposureKeys(publishToken: String?, visitedCountries: Set<EFGSCountry>, shareWithEFGS: Bool) -> AnyPublisher<Void, Error>
    func postDummyKeys() -> AnyPublisher<Void, Error>
    func refreshStatus()
    func setStatus(enabled: Bool)
    func tryEnable(_ completionHandler: @escaping (ENError.Code?) -> Void)
    func deleteBatchFiles()
    func removeExpiredExposures()
    func showExposureNotification(delay: TimeInterval?)
    
    var isEndOfLife: Bool { get }
    var onEndOfLife: AnyPublisher<Void, Never> { get }
}

struct ExposureRepositoryImpl : ExposureRepository {
    static let keyCount = 14
    static let manualCheckThreshold: TimeInterval = .days(1)
    
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
        
        return LocalStore.shared.$uiStatus.$wrappedValue
            .combineLatest(isDelayed,
                           BackgroundTaskForNotifications.shared.$detectionRunning) {
                .init(status: $0, delayed: $1, running: $2)
            }
            .removeDuplicates()
            .shareCurrent()
            .eraseToAnyPublisher()
    }()
    
    let efgsRepository: EFGSRepository
    let exposureManager: ExposureManager
    let notificationService: NotificationService
    let backend: Backend
    let storage: FileStorage
    
    func detectionStatus() -> AnyPublisher<DetectionStatus, Never> {
        Self.detectionStatus
    }
    
    func timeFromLastCheck() -> AnyPublisher<TimeInterval?, Never> {
        Self.timeFromLastCheck
    }
    
    func exposureStatus() -> AnyPublisher<ExposureStatus, Never> {
        LocalStore.shared.$exposures.$wrappedValue
            .combineLatest(getExposureNotifications())
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
    
    func getExposureNotifications() -> AnyPublisher<[ExposureNotification], Never> {
        LocalStore.shared.$daysExposureNotifications.$wrappedValue
            .combineLatest(LocalStore.shared.$countExposureNotifications.$wrappedValue)
            .map { countNotifications, daysNotifications -> [ExposureNotification] in
                return daysNotifications + countNotifications
            }.eraseToAnyPublisher()
    }
    
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
        return backend.getConfiguration().receive(on: RunLoop.main).map { config in
            if config.endOfLifeReached {
                LocalStore.shared.endOfLifeStatisticsData = config.endOfLifeStatistics
                notificationService.updateBadgeNumber(nil)
                LocalStore.shared.exposures.removeAll()
                LocalStore.shared.countExposureNotifications.removeAll()
                LocalStore.shared.daysExposureNotifications.removeAll()
                
                if exposureManager.exposureNotificationStatus != .unauthorized {
                    setStatus(enabled: false)
                }
            }
      
            return config
        }
        .eraseToAnyPublisher()
    }
    
    var isEndOfLife: Bool {
        !LocalStore.shared.endOfLifeStatisticsData.isEmpty
    }
    
    var onEndOfLife: AnyPublisher<Void, Never> {
        LocalStore.shared.$endOfLifeStatisticsData.$wrappedValue
            .filter { !$0.isEmpty }
            .map { _ in }
            .eraseToAnyPublisher()
    }
        
    func detectExposures(ids: [String], config: ExposureConfiguration) -> AnyPublisher<Bool, Error> {
        
        let urls = ids.map { self.storage.getFileUrls(forBatchId: $0) }.flatMap { $0 }
        Log.d("Ids: \(ids), Config: \(config), Detecting with urls: \(urls)")
        
        return self.exposureManager.detectExposures(configuration: config,
                                                    diagnosisKeyURLs: urls)
            .flatMap { summary in
                Just(summary).setFailureType(to: Error.self).zip(
                    self.exposureManager.getExposureWindows(summary: summary))
            }
            .map { (summary, windows) -> [Date] in
                Log.d("Got day summaries: \(summary.daySummaries)")
                
                if let latestId = ids.sorted().last {
                    LocalStore.shared.nextDiagnosisKeyFileIndex = latestId
                }
                
                #if DEBUG
                // When debugging, store detection summary to local store for debugging purposes
                let data = ExposureDetectionData(summary: summary, windows: windows)
                LocalStore.shared.detectionData.insert(data, at: 0)
                
                windows.forEach { window in Log.d("window=\(window), scanInstances=\(window.scanInstances)") }
                #endif
                
                let latestExposureDay = LocalStore.shared.latestExposureDate()
                
                // Only show a notification if the score is great enough and
                // if the exposure date is after the newest previously known exposure's.
                let newExposureDays = summary.daySummaries
                    .filter { Int($0.daySummary.scoreSum) >= config.minimumDailyScore }
                    .filter { latestExposureDay == nil || $0.date > latestExposureDay! }
                    .map { $0.date }
                
                return newExposureDays
            }
            .receive(on: RunLoop.main)
            .map { newExposureDays -> Bool in
                guard !newExposureDays.isEmpty else { return false }
                Log.d("New exposures: \(newExposureDays)")
                
                let notification = DaysExposureNotification(exposureDays: newExposureDays)
                LocalStore.shared.daysExposureNotifications.append(notification)
                showExposureNotification()
                
                return true
            }
            .eraseToAnyPublisher()
    }
    
    func deleteBatchFiles() {
        // Since we are only processing 1 batch set at a time, always clean up the entire batches directory.
        storage.deleteAllBatches()
    }
    
    func postExposureKeys(publishToken: String?,
                          visitedCountries: Set<EFGSCountry>,
                          shareWithEFGS: Bool) -> AnyPublisher<Void, Error> {
        
        return self.exposureManager.getDiagnosisKeys()
            .flatMap { enTemporaryExposureKeys -> AnyPublisher<Data, Error> in
                let tempKeys = self.mapKeysToCorrectLength(enTemporaryExposureKeys: enTemporaryExposureKeys)
                let publishRequest = DiagnosisPublishRequest(keys: tempKeys,
                                                             visitedCountries: efgsRepository.mask(visitedCountries: visitedCountries),
                                                             consentToShareWithEfgs: shareWithEFGS ? 1 : 0)
                
                Log.d("Post \(tempKeys.count) keys")
                return self.backend.postDiagnosisKeys(publishToken: publishToken,
                                                      publishRequest: publishRequest,
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
        let publishRequest = DiagnosisPublishRequest(keys: keys,
                                                     visitedCountries: efgsRepository.mask(visitedCountries: Set()),
                                                     consentToShareWithEfgs: 0)
        
        Log.d("Dummy post \(keys.count) dummy keys")
        return self.backend.postDiagnosisKeys(publishToken: ExposureRepositoryImpl.dummyPostToken,
                                              publishRequest: publishRequest,
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
        
        switch status {
        case .on:
            notificationService.isEnabled { enabled in
                applyStatus(status: enabled ? .on : .notificationsOff)
            }
            
        default:
            applyStatus(status: status)
        }
    }
    
    private func applyStatus(status: RadarStatus) {
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
    
    func removeExpiredExposures() {
        LocalStore.shared.removeExpiredExposures()
        notificationService.updateBadgeNumber(LocalStore.shared.exposureNotificationCount)
    }
    
    func showExposureNotification(delay: TimeInterval? = nil) {
        notificationService.showNotification(title: Translation.ExposureNotificationTitle.localized,
                                             body: Translation.ExposureNotificationBody.localized,
                                             delay: delay,
                                             badgeNumber: LocalStore.shared.exposureNotificationCount)
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

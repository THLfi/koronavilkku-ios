
import Foundation
import ExposureNotification
import Combine

@propertyWrapper
class Persisted<Value: Codable> {
    
    init(userDefaultsKey: String, notificationName: Notification.Name, defaultValue: Value) {
        self.userDefaultsKey = userDefaultsKey
        self.notificationName = notificationName
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                wrappedValue = try JSONDecoder().decode(Value.self, from: data)
            } catch {
                wrappedValue = defaultValue
            }
        } else {
            wrappedValue = defaultValue
        }
    }
    
    let userDefaultsKey: String
    let notificationName: Notification.Name
    
    @Published var wrappedValue: Value {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(wrappedValue), forKey: userDefaultsKey)
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    var projectedValue: Persisted<Value> { self }
    
    @discardableResult
    func addObserver(using block: @escaping () -> Void) -> AnyObject {
        return NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            block()
        }
    }
}

class LocalStore : BatchIdCache {
    
    static let shared = LocalStore()
    
    @Persisted(userDefaultsKey: "isOnboarded", notificationName: .init("LocalStoreIsOnboardedDidChange"), defaultValue: false)
    var isOnboarded: Bool
    
    @Persisted(userDefaultsKey: "onboardingResumeStep", notificationName: .init("LocalStoreOnboardingResumeStepDidChange"), defaultValue: nil)
    var onboardingResumeStep: Int?
    
    @Persisted(userDefaultsKey: "nextDiagnosisKeyFileIndex", notificationName: .init("LocalStoreNextDiagnosisKeyFileIndexDidChange"), defaultValue: nil)
    var nextDiagnosisKeyFileIndex: String?
    
    @Persisted(userDefaultsKey: "exposures", notificationName: .init("LocalStoreExposuresDidChange"), defaultValue: [])
    var exposures: [Exposure]
    
    @Persisted(userDefaultsKey: "exposureNotifications", notificationName: .init("LocalStoreExposureNotificationsDidChange"), defaultValue: [])
    var countExposureNotifications: [CountExposureNotification]
    
    @Persisted(userDefaultsKey: "daysExposureNotifications", notificationName: .init("LocalStoreExposuresBundlesDidChange"), defaultValue: [])
    var daysExposureNotifications: [DaysExposureNotification]
    
    @Persisted(userDefaultsKey: "dateLastPerformedExposureDetection",
               notificationName: .init("LocalStoreDateLastPerformedExposureDetectionDidChange"), defaultValue: nil)
    private (set) var dateLastPerformedExposureDetection: Date?

    @Persisted(userDefaultsKey: "uiStatus", notificationName: .init("LocalStoreUIStatus"), defaultValue: .on)
    var uiStatus: RadarStatus
    
    @Persisted(userDefaultsKey: "detectionSummaries", notificationName: .init("LocalStoreDetectionSummaries"), defaultValue: [])
    var detectionSummaries: [ExposureDetectionSummary]
    
    func updateDateLastPerformedExposureDetection() {
        dateLastPerformedExposureDetection = Date()
    }

    func removeExpiredExposures() {
        let now = Date()
        exposures.removeAll { $0.deleteDate < now }
        countExposureNotifications.removeAll { $0.expiresOn < now }
        daysExposureNotifications.removeAll { $0.expiresOn < now }
    }
    
    func resetExposures() {
        exposures = []
        countExposureNotifications = []
        daysExposureNotifications = []
        dateLastPerformedExposureDetection = nil
    }
    
    var exposureNotificationCount: Int {
        countExposureNotifications.count + daysExposureNotifications.count
    }
    
    func latestExposureDate() -> Date? {
        var result = daysExposureNotifications.map { $0.latestExposureDate }
        result.append(contentsOf: countExposureNotifications.map { $0.latestExposureDate })
        result.append(contentsOf: exposures.map { $0.date })
        return result.max()
    }
}

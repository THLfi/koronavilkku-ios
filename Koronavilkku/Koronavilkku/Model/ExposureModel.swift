import Foundation
import ExposureNotification

enum ExposureStatus: Equatable {
    case unexposed
    case exposed(notificationCount: Int?)
}

protocol ExposureNotification: Codable {
    var detectedOn: Date { get }
    var expiresOn: Date { get }
    var detectionInterval: DateInterval { get }
    var latestExposureDate: Date { get }
}

extension ExposureNotification {

    var latestExposureDate: Date {
        // ExposureNotificationSpec.exposureNotificationValid isn't necessarily the correct value
        // for this particular notification in case it is made with an old version that used 10d intervals.
        let validDays = ((self.detectionInterval.duration + .day) / .day).rounded(.down)
        return self.expiresOn.addingTimeInterval(-1 * .days(validDays + 1))
    }
}

struct DaysExposureNotification: ExposureNotification {
    let detectedOn: Date
    let expiresOn: Date
    let detectionInterval: DateInterval

    let dayCount: Int

    init(detectedOn: Date = .init(), exposureDays: [Date]) {
        let latestExposureDate = exposureDays.max() ?? detectedOn
        self.detectedOn = detectedOn
        self.expiresOn = ExposureNotificationSpec.calculateRetentionTime(timeOfExposure: latestExposureDate)
        self.detectionInterval = ExposureNotificationSpec.calculateDetectionInterval(from: detectedOn)
        self.dayCount = exposureDays.count
    }
}

/// This is the old V1 way of storing exposure notifications.
struct CountExposureNotification: ExposureNotification {
    /// Defines when this app detected the exposure, i.e. approximately when detectExposures() was called.
    let detectedOn: Date
    let expiresOn: Date
    let detectionInterval: DateInterval

    let exposureCount: Int
    
    init(detectionTime: Date, latestExposureOn: Date, exposureCount: Int) {
        self.detectedOn = detectionTime
        self.expiresOn = ExposureNotificationSpec.calculateRetentionTime(timeOfExposure: latestExposureOn)
        self.detectionInterval = ExposureNotificationSpec.calculateDetectionInterval(from: detectionTime)
        self.exposureCount = exposureCount
    }
}

fileprivate struct ExposureNotificationSpec {
    typealias Days = Double
    
    /// The number of days an exposure notification is being shown after the exposure
    ///
    /// This property could be moved to the configuration, but as our UI texts are
    /// currently static, this is also fixed.
    static let exposureNotificationValid: Days = 14
    
    /// The number of days exposure detection goes back in time to find potential exposures
    ///
    /// While this value could be determined from the EN configuration, V1 API does not
    /// provide enough granularity we need. We can revisit this issue later once we've moved
    /// to the V2 API.
    static let exposureDetectionInterval: Days = 14
    
    /// Determines the exposure notification retention time
    ///
    /// The official exposure retention time is calculated from the time of exposure.
    /// As we don't know the exact time of exposure, just the 24-hour window starting
    /// from 00:00 UTC, we need to add one additional 24-hour window to make sure every
    /// possible exposure is covered.
    static func calculateRetentionTime(timeOfExposure: Date) -> Date {
        timeOfExposure.addingTimeInterval(.days(Self.exposureNotificationValid + 1))
    }
    
    /// Calculates the date range used to detect exposures from the detection time
    ///
    /// The interval does not contain the current day, as our current implementation
    /// creates the batch files from the TEK's issued in the previous day. Therefore the
    /// interval is "one day shorter".
    static func calculateDetectionInterval(from detectionTime: Date) -> DateInterval {
        .init(start: detectionTime.addingTimeInterval(.days(0 - Self.exposureDetectionInterval)),
              duration: .days(Self.exposureDetectionInterval - 1))
    }
}

/// Single exposure object
///
/// - Important: Deprecated, use ExposureNotification instead
struct Exposure: Codable {
    /// How long the notification is being shown after the exposure
    ///
    /// We're still using the old value here on purpose, because the retention
    /// time is a computed property based on this value and this is the last
    /// value we have shipped and therefore is the most likely expiration time.
    static let retentionTime: TimeInterval = .days(10 + 1)
    
    let date: Date
    
    var deleteDate: Date {
        get {
            date.addingTimeInterval(Self.retentionTime)
        }
    }
}

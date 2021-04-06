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

struct DaysExposureNotification: ExposureNotification {
    let detectedOn: Date
    let expiresOn: Date
    let detectionInterval: DateInterval

    let dayCount: Int

    init(detectedOn: Date = .init(), exposureDays: [Date]) {
        let latestExposureDate = exposureDays.max() ?? detectedOn
        self.detectedOn = detectedOn
        self.expiresOn = ExposureNotificationSpec.calculateRetentionTime(timeOfExposure: latestExposureDate)
        self.detectionInterval = ExposureNotificationSpec.calculateDetectionInterval(from: detectedOn, shortenedRollingPeriod: true)
        self.dayCount = exposureDays.count
    }

    // Computed properties of a Codable aren't included in the encoded data.
    var latestExposureDate: Date {
        return ExposureNotificationSpec.calculateLatestExposureDate(from: self, shortenedRollingPeriod: true)
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
        self.detectionInterval = ExposureNotificationSpec.calculateDetectionInterval(from: detectionTime, shortenedRollingPeriod: false)
        self.exposureCount = exposureCount
    }
    
    var latestExposureDate: Date {
        return ExposureNotificationSpec.calculateLatestExposureDate(from: self, shortenedRollingPeriod: false)
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
    /// If shortenedRollingPeriod is false, then the interval does not contain the
    /// current day, as our current implementation creates the batch files from
    /// the TEK's issued in the previous day. Therefore the interval is "one day shorter".
    static func calculateDetectionInterval(from detectionTime: Date, shortenedRollingPeriod: Bool) -> DateInterval {
        .init(start: detectionTime.addingTimeInterval(.days(0 - Self.exposureDetectionInterval)),
              duration: .days(Self.exposureDetectionInterval - (shortenedRollingPeriod ? 0 : 1)))
    }
    
    /// Calculates latestExposureOn from the notification's detectionInterval and expiresOn.
    ///
    /// ExposureNotificationSpec.exposureNotificationValid isn't necessarily the correct value
    /// for a particular notification in case it is made with an old version that used 10d intervals.
    /// In the V2 era the 1d reduction is no longer needed in detection interval (shortenedRollingPeriod=true).
    static func calculateLatestExposureDate(from notification: ExposureNotification, shortenedRollingPeriod: Bool) -> Date {
        let retentionTime = notification.detectionInterval.duration + .day * (shortenedRollingPeriod ? 0 : 1)
        let retentionDays = (retentionTime / .day).rounded(.down)
        return notification.expiresOn.addingTimeInterval(-1 * .days(retentionDays + 1))
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

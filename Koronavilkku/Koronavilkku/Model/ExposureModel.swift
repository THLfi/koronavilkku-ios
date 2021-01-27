import Foundation
import ExposureNotification

enum ExposureStatus: Equatable {
    case unexposed
    case exposed(notificationCount: Int?)
}

struct ExposureNotification: Codable {
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
    
    let detectedOn: Date
    let expiresOn: Date
    let detectionInterval: DateInterval
    let exposureCount: Int
    
    init(detectionTime: Date, latestExposureOn: Date, exposureCount: Int) {
        self.detectedOn = detectionTime
        self.expiresOn = ExposureNotification.calculateRetentionTime(timeOfExposure: latestExposureOn)
        self.detectionInterval = ExposureNotification.calculateDetectionInterval(from: detectionTime)
        self.exposureCount = exposureCount
    }

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

extension Collection where Element : ENExposureInfo {
    func to(config: ExposureConfiguration, detectionTime: Date = .init()) -> ExposureNotification {
        let exposures = filter { info in
            info.totalRiskScore >= config.minimumRiskScore
        }
        
        let latestExposureOn: Date
        let exposureCount: Int
        
        if !exposures.isEmpty {
            latestExposureOn = exposures.max { $0.date < $1.date }!.date
            exposureCount = exposures.count
        } else {
            latestExposureOn = self.max { $0.date < $1.date }?.date ?? detectionTime
            exposureCount = 1
        }
        
        return ExposureNotification(detectionTime: detectionTime,
                                    latestExposureOn: latestExposureOn,
                                    exposureCount: exposureCount)
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

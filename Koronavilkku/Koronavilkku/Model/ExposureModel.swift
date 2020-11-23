import Foundation
import ExposureNotification

enum ExposureStatus: Equatable {
    case unexposed
    case exposed(notificationCount: Int?)
}

struct ExposureNotification: Codable {
    /// How long the notification is being shown after the exposure
    ///
    /// The official exposure retention time is 10 * 24 hours from the time of exposure.
    /// As we don't know the exact time of exposure, just the 24-hour window starting
    /// from 00:00 UTC, we need to add one additional 24-hour window to make sure every
    /// possible exposure is covered.
    static let retentionTime: TimeInterval = .days(10 + 1)
    
    /// Detection duration is 10 days long
    static let detectionIntervalDuration: TimeInterval = .days(9)
    static let detectionIntervalStart: TimeInterval = .days(-10)

    let detectedOn: Date
    let expiresOn: Date
    let detectionInterval: DateInterval
    let exposureCount: Int
    
    init(detectionTime: Date, latestExposureOn: Date, exposureCount: Int) {
        self.detectedOn = detectionTime
        self.expiresOn = latestExposureOn.addingTimeInterval(ExposureNotification.retentionTime)
        self.detectionInterval = DateInterval(start: detectionTime.addingTimeInterval(Self.detectionIntervalStart),
                                              duration: Self.detectionIntervalDuration)
        self.exposureCount = exposureCount
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
    static let retentionTime: TimeInterval = .days(10 + 1)
    
    let date: Date
    
    var deleteDate: Date {
        get {
            date.addingTimeInterval(Self.retentionTime)
        }
    }
}

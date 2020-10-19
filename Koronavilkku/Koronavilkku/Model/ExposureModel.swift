import Foundation
import ExposureNotification

struct Exposure: Codable {
    // The official exposure retention time is 10 * 24 hours from the time of exposure.
    // As we don't know the exact time of exposure, just the 24-hour window starting
    // from 00:00 UTC, we need to round it up to the next UTC midnight to make sure
    // every possible exposure is covered
    static let retentionTime: TimeInterval = (10 + 1) * 86_400
    
    let date: Date
    
    var deleteDate: Date {
        get {
            date.addingTimeInterval(Self.retentionTime)
        }
    }
}

extension ENExposureInfo {
    func to() -> Exposure {
        Exposure(date: self.date)
    }
}

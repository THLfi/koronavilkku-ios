import Foundation
import ExposureNotification

struct Exposure: Codable {
    
    static let retentionTime: Double = (60 * 60 * 24) * 15 // 15 days
    static let testRetentionTime: Double = 60 * 10 // 10 minutes
    
    let date: Date
    let deleteDate: Date
    
    init(date: Date) {
        self.date = date
        self.deleteDate = date.addingTimeInterval(Exposure.retentionTime)
    }
}

extension ENExposureInfo {
    func to() -> Exposure {
        Exposure(date: self.date)
    }
}

extension Exposure: Comparable {
    static func < (lhs: Exposure, rhs: Exposure) -> Bool {
        return lhs.date < rhs.date
    }
}

extension ENExposureInfo {
    func toExposureTest() -> Exposure {
        Exposure(date: Date())
    }
}

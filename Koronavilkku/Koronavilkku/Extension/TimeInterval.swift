import Foundation

extension TimeInterval {
    static let hour = TimeInterval(60 * 60)
    static let day = hour * 24
    
    static func days(_ numberOfDays: Double) -> TimeInterval {
        TimeInterval.day * numberOfDays
    }
    
    static func hours(_ numberOfHours: Double) -> TimeInterval {
        TimeInterval.hour * numberOfHours
    }
}


import Foundation

extension Date {
    init(dateString:String) {
        self = Date.iso8601Formatter.date(from: dateString)!
    }
    
    func shortIso8601Time() -> String {
        return Date.iso8601ShortTimeFormatter.string(from: self)
    }
    
    func shortLocalDate() -> String {
        return Date.shortLocalDate.string(from: self)
    }
    
    func toLocalizedRelativeFormat() -> String {
        return RelativeDateTimeFormatter().localizedString(for: self, relativeTo: Date())
    }

    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                          .withTime,
                                          .withDashSeparatorInDate,
                                          .withColonSeparatorInTime]
        return formatter
    }()
    
    static let iso8601ShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let shortLocalDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

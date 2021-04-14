import Foundation
import ExposureNotification

struct ExposureDetectionData: Codable, CustomStringConvertible {
    var creationTime = Date()
    let daySummaries: [ExposureDaySummary]
    let windows: [ExposureWindow]

    var description: String {
        var rows: [String] = []
        rows.append(creationTime.shortLocalDateTime())
        rows.append("Summaries:")
        rows.append(contentsOf: daySummaries.map { $0.description })
        rows.append("Windows:")
        rows.append(contentsOf: windows.map { $0.description })
        return rows.joined(separator: "\n")
    }
}

extension ExposureDetectionData {
    init(summary: ENExposureDetectionSummary, windows: [ENExposureWindow]) {
        self.daySummaries = summary.daySummaries.map { $0.to() }
        self.windows = windows.map { $0.to() }
    }
}

struct ExposureDaySummary: Codable, CustomStringConvertible {
    let date: Date
    let maximumScore: Double
    let scoreSum: Double
    let weightedDurationSum: TimeInterval
    
    var description: String {
        return "\(date.shortLocalDate()) sum:\(Int(scoreSum)) max:\(Int(maximumScore)) dur:\(Int(weightedDurationSum))"
    }
}

extension ENExposureDaySummary {
    func to() -> ExposureDaySummary {
        return ExposureDaySummary(date: date,
                                  maximumScore: daySummary.maximumScore,
                                  scoreSum: daySummary.scoreSum,
                                  weightedDurationSum: daySummary.weightedDurationSum)
    }
}

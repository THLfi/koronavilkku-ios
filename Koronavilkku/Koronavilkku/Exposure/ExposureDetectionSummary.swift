
import Foundation
import ExposureNotification


struct ExposureDetectionSummary: Codable, CustomStringConvertible {
    var description: String {
        return [
            "Creation time: \(creationTime)",
            "daySummaries: \(daySummaries)",
            ].joined(separator: "\n")
    }

    var creationTime = Date()
    let daySummaries: [String]
}

extension ENExposureDetectionSummary {
    
    func to() -> ExposureDetectionSummary {
        // Only daySummaries is stored because in V2 the other values seem to be undefined.
        return ExposureDetectionSummary(daySummaries: self.daySummaries.map { $0.description })
    }
}

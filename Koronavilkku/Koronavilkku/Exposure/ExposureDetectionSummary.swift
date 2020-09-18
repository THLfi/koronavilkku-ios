
import Foundation
import ExposureNotification


struct ExposureDetectionSummary: Codable, CustomStringConvertible {
    var description: String {
        return [
            "Creation time: \(creationTime)",
            "attenuationDurations: \(attenuationDurations)",
            "daysSinceLastExposure: \(daysSinceLastExposure)",
            "matchedKeyCount: \(matchedKeyCount)",
            "maximumRiskScore: \(maximumRiskScore)",
            "maximumRiskScoreFullRange: \(maximumRiskScoreFullRange)",
            "riskScoreSumFullRange: \(riskScoreSumFullRange)"
            ].joined(separator: "\n")
    }
    

    var creationTime = Date()
    let attenuationDurations: [Double]
    let daysSinceLastExposure: Int
    let matchedKeyCount: UInt64
    let maximumRiskScore: ENRiskScore
    let maximumRiskScoreFullRange: Double
    let riskScoreSumFullRange: Double
    
}

extension ENExposureDetectionSummary {
    
    func to() -> ExposureDetectionSummary {
        return ExposureDetectionSummary(attenuationDurations: self.attenuationDurations.map { Double(truncating: $0) },
                                        daysSinceLastExposure: self.daysSinceLastExposure,
                                        matchedKeyCount: self.matchedKeyCount,
                                        maximumRiskScore: self.maximumRiskScore,
                                        maximumRiskScoreFullRange: self.maximumRiskScoreFullRange,
                                        riskScoreSumFullRange: self.riskScoreSumFullRange)
    }
}

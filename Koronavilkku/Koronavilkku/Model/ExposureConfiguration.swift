import ExposureNotification
import Foundation

struct ExposureConfiguration: Codable {
    let minimumRiskScore: Int
    let attenuationScores: [Int]
    let daysSinceLastExposureScores: [Int]
    let durationScores: [Int]
    let transmissionRiskScores: [Int]
    let durationAtAttenuationThresholds: [Int]
    let durationAtAttenuationWeights: [Double]
    let exposureRiskDuration: Int // In minutes.
    let participatingCountries: [String]
}

extension ENExposureConfiguration {
    convenience init(from: ExposureConfiguration) {
        self.init()
        let convertLevelValues = { NSNumber(integerLiteral: $0) }
        attenuationLevelValues = from.attenuationScores.map(convertLevelValues)
        daysSinceLastExposureLevelValues = from.daysSinceLastExposureScores.map(convertLevelValues)
        minimumRiskScoreFullRange = Double(from.minimumRiskScore)
        minimumRiskScore = ENRiskScore(clamp(from.minimumRiskScore, minValue: 0, maxValue: 255))
        transmissionRiskLevelValues = from.transmissionRiskScores.map(convertLevelValues)
        durationLevelValues = from.durationScores.map(convertLevelValues)
        
        if #available(iOS 13.6, *) {
            attenuationDurationThresholds = from.durationAtAttenuationThresholds.map(convertLevelValues)
        }
    }
}

extension ExposureConfiguration {

    func with(minimumRiskScore: Int) -> ExposureConfiguration {
        return ExposureConfiguration(
            minimumRiskScore: minimumRiskScore,
            attenuationScores: attenuationScores,
            daysSinceLastExposureScores: daysSinceLastExposureScores,
            durationScores: durationScores,
            transmissionRiskScores: transmissionRiskScores,
            durationAtAttenuationThresholds: durationAtAttenuationThresholds,
            durationAtAttenuationWeights: durationAtAttenuationWeights,
            exposureRiskDuration: exposureRiskDuration,
            participatingCountries: participatingCountries)
    }
}

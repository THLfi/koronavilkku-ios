import ExposureNotification
import Foundation


// TODO: Remove these in future releases
// attenuationWeight
// daysSinceLastExposureWeight
// durationWeight
// transmissionRiskWeight
struct ExposureConfiguration: Codable {
    let minimumRiskScore: Int
    let attenuationScores: [Int]
    let attenuationWeight: Int?
    let daysSinceLastExposureScores: [Int]
    let daysSinceLastExposureWeight: Int?
    let durationScores: [Int]
    let durationWeight: Int?
    let transmissionRiskScores: [Int]
    let transmissionRiskWeight: Int?
    let durationAtAttenuationThresholds: [Int]
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
        
        // Add also deprecated parameters, if backend provides them
        if let _ = from.attenuationWeight {
            attenuationWeight = Double(from.attenuationWeight!)
        }
    
        if let _ = from.daysSinceLastExposureWeight {
            daysSinceLastExposureWeight = Double(from.daysSinceLastExposureWeight!)
        }
        
        durationLevelValues = from.durationScores.map(convertLevelValues)
        if let _ = from.durationWeight {
            durationWeight = Double(from.durationWeight!)
        }
        
        if let _ = from.transmissionRiskWeight {
            transmissionRiskWeight = Double(from.transmissionRiskWeight!)
        }
    }
}

extension ExposureConfiguration {

    func with(minimumRiskScore: Int) -> ExposureConfiguration {
        return ExposureConfiguration(
            minimumRiskScore: minimumRiskScore,
            attenuationScores: attenuationScores,
            attenuationWeight: attenuationWeight,
            daysSinceLastExposureScores: daysSinceLastExposureScores,
            daysSinceLastExposureWeight: daysSinceLastExposureWeight,
            durationScores: durationScores,
            durationWeight: durationWeight,
            transmissionRiskScores: transmissionRiskScores,
            transmissionRiskWeight: transmissionRiskWeight,
            durationAtAttenuationThresholds: durationAtAttenuationThresholds)
    }
}

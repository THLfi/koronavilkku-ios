import ExposureNotification
import Foundation

struct ExposureConfiguration: Codable {
    let version: Int
    
    let reportTypeWeightConfirmedTest: Double
    let reportTypeWeightConfirmedClinicalDiagnosis: Double
    let reportTypeWeightSelfReport: Double
    let reportTypeWeightRecursive: Double
    
    let infectiousnessWeightStandard: Double
    let infectiousnessWeightHigh: Double
    
    let attenuationBucketThresholdDb: [Int]
    let attenuationBucketWeights: [Double]

    let daysSinceExposureThreshold: Int
    let minimumWindowScore: Double
    let minimumDailyScore: Int

    let daysSinceOnsetToInfectiousness: [String: String]
    
    let infectiousnessWhenDaysSinceOnsetMissing: String

    let availableCountries: [String]
    
    func infectiousnessForDaysSinceOnsetOfSymptoms() -> [NSNumber: NSNumber] {
        let mapInfectiousness = { (value: String) -> ENInfectiousness in
            switch value {
            case "HIGH":
                return .high
            case "STANDARD":
                return .standard
            default:
                return .none
            }
        }

        var infectiousnessForDays: [Int: String] = daysSinceOnsetToInfectiousness.reduce(into: [:]) { (list, item) in
            if let day = Int(item.key) {
                list[day] = item.value
            }
        }

        if #available(iOS 14.0, *) {
            infectiousnessForDays[ENDaysSinceOnsetOfSymptomsUnknown] = infectiousnessWhenDaysSinceOnsetMissing
        } else {
            // ENDaysSinceOnsetOfSymptomsUnknown is not available in earlier versions of iOS; use an equivalent value.
            infectiousnessForDays[NSIntegerMax] = infectiousnessWhenDaysSinceOnsetMissing
        }

        return infectiousnessForDays.mapValues { mapInfectiousness($0).rawValue } as [NSNumber: NSNumber]
    }
}


extension ENExposureConfiguration {
    convenience init(from: ExposureConfiguration) {
        self.init()
        
        func weight(of apiValue: Double) -> Double {
            apiValue * 100
        }
        
        attenuationDurationThresholds = from.attenuationBucketThresholdDb.map(NSNumber.init)
        minimumRiskScoreFullRange = from.minimumWindowScore

        immediateDurationWeight = weight(of: from.attenuationBucketWeights[0])
        nearDurationWeight = weight(of: from.attenuationBucketWeights[1])
        mediumDurationWeight = weight(of: from.attenuationBucketWeights[2])
        otherDurationWeight = weight(of: from.attenuationBucketWeights[3])
        
        daysSinceLastExposureThreshold = from.daysSinceExposureThreshold
        
        infectiousnessForDaysSinceOnsetOfSymptoms = from.infectiousnessForDaysSinceOnsetOfSymptoms()
        infectiousnessHighWeight = weight(of: from.infectiousnessWeightHigh)
        infectiousnessStandardWeight = weight(of: from.infectiousnessWeightStandard)
        
        reportTypeConfirmedTestWeight = weight(of: from.reportTypeWeightConfirmedTest)
        reportTypeConfirmedClinicalDiagnosisWeight = weight(of: from.reportTypeWeightConfirmedClinicalDiagnosis)
        reportTypeRecursiveWeight = weight(of: from.reportTypeWeightRecursive)
        reportTypeSelfReportedWeight = weight(of: from.reportTypeWeightSelfReport)
        reportTypeNoneMap = ENDiagnosisReportType.confirmedTest
    }
}

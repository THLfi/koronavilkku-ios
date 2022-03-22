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
    
    let endOfLifeReached: Bool
    let endOfLifeStatistics: [EndOfLifeStatistic]
   // let endOfLifeStatistics: [String : [String : String]]

    let daysSinceOnsetToInfectiousness: [String: String]

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

        // The keys received from the backend always include the DSOS value so we don't need to
        // assign a value (infectiousnessWhenDaysSinceOnsetMissing) for key ENDaysSinceOnsetOfSymptomsUnknown
        // (which is deprecated on >=14).

        return daysSinceOnsetToInfectiousness.reduce(into: [:]) { (list, item) in
            if let day = Int(item.key) {
                list[NSNumber(value: day)] = NSNumber(value: mapInfectiousness(item.value).rawValue)
            }
        }
    }
}

// MARK: - EndOfLifeStatistic
struct EndOfLifeStatistic: Codable {
    let value, label: Languages
}

// MARK: - Label
struct Languages: Codable {
    let en, fi, sv: String
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

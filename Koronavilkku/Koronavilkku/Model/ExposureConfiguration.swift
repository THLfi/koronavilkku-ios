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

    let daysSinceOnsetToinfectiousness: [String: String]
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
        
        return daysSinceOnsetToinfectiousness.reduce(into: [:]) { (list, item) in
            if let day = Int(item.key) {
                list[NSNumber(value: day)] = NSNumber(value: mapInfectiousness(item.value).rawValue)
            }
        }
    }
}


extension ENExposureConfiguration {
    convenience init(from: ExposureConfiguration) {
        self.init()
        
        func weight(of apiValue: Double) -> Double {
            apiValue * 100
        }
        
        attenuationDurationThresholds = from.attenuationBucketThresholdDb.map(NSNumber.init)
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

extension ExposureConfiguration {

    func with(minimumRiskScore: Int) -> ExposureConfiguration {
        return ExposureConfiguration(version: version,
                                     reportTypeWeightConfirmedTest: reportTypeWeightConfirmedTest,
                                     reportTypeWeightConfirmedClinicalDiagnosis: reportTypeWeightConfirmedClinicalDiagnosis,
                                     reportTypeWeightSelfReport: reportTypeWeightSelfReport,
                                     reportTypeWeightRecursive: reportTypeWeightRecursive,
                                     infectiousnessWeightStandard: infectiousnessWeightStandard,
                                     infectiousnessWeightHigh: infectiousnessWeightHigh,
                                     attenuationBucketThresholdDb: attenuationBucketThresholdDb,
                                     attenuationBucketWeights: attenuationBucketWeights,
                                     daysSinceExposureThreshold: daysSinceExposureThreshold,
                                     minimumWindowScore: Double(minimumRiskScore),
                                     daysSinceOnsetToinfectiousness: daysSinceOnsetToinfectiousness,
                                     infectiousnessWhenDaysSinceOnsetMissing: infectiousnessWhenDaysSinceOnsetMissing,
                                     availableCountries: availableCountries)
            
    }
}

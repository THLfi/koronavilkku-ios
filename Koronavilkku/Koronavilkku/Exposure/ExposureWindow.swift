import Foundation
import ExposureNotification

struct ExposureWindow: Codable, CustomStringConvertible {
    let date: Date
    let calibrationConfidence: UInt8
    let diagnosisReportType: UInt32
    let infectiousness: UInt32
    let scanInstances: [ScanInstance]
    
    var description: String {
        var rows = scanInstances.map { "  \($0)" }
        rows.insert("\(date.shortLocalDate()) cc:\(calibrationConfidence) drt:\(diagnosisReportType) inft:\(infectiousness)", at: 0)
        return rows.joined(separator: "\n")
    }
}

struct ScanInstance: Codable, CustomStringConvertible {
    let minimumAttenuation: ENAttenuation
    let typicalAttenuation: ENAttenuation
    let secondsSinceLastScan: Int
    
    var description: String {
        "typ:\(typicalAttenuation), min:\(minimumAttenuation), sec:\(secondsSinceLastScan)"
    }
}

extension ENExposureWindow {
    func to() -> ExposureWindow {
        return ExposureWindow(date: date,
                              calibrationConfidence: calibrationConfidence.rawValue,
                              diagnosisReportType: diagnosisReportType.rawValue,
                              infectiousness: infectiousness.rawValue,
                              scanInstances: scanInstances.map { $0.to() })
    }
}

extension ENScanInstance {
    func to() -> ScanInstance {
        ScanInstance(minimumAttenuation: minimumAttenuation,
                     typicalAttenuation: typicalAttenuation,
                     secondsSinceLastScan: secondsSinceLastScan)
    }
}

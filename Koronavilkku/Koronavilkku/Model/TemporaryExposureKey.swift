import ExposureNotification
import Foundation

struct TemporaryExposureKey : Codable, Equatable {
    
    enum DataGenerationError: Error {
        case errorGeneratingRandomData
    }
    
    static let dataLength = 16
    
    let keyData: String
    let transmissionRiskLevel: Int
    let rollingStartIntervalNumber: Int
    let rollingPeriod: Int
    
    static func createDummy(index: Int) -> TemporaryExposureKey {
        
        // A whole lot of magic numbers here, but this is according to Google's GAEN API specs
        TemporaryExposureKey(
            keyData: randomData(ofLength: dataLength),
            transmissionRiskLevel: index % 7,
            rollingStartIntervalNumber: 2650847,
            rollingPeriod: 144
        )
    }
    
    static func randomData(ofLength length: Int) -> String {
        Data([UInt8](repeating: 0, count: length).map { _ in
            UInt8.random(in: UInt8.min...UInt8.max)
        }).base64EncodedString()
    }
}

extension ENTemporaryExposureKey {
    func toTemporaryExposureKey() -> TemporaryExposureKey {
        TemporaryExposureKey(
            keyData: keyData.base64EncodedString(),
            transmissionRiskLevel: Int(transmissionRiskLevel),
            rollingStartIntervalNumber: Int(rollingStartNumber),
            rollingPeriod: Int(rollingPeriod)
        )
    }
}

import ExposureNotification
import Foundation

struct TemporaryExposureKey : Codable {
    
    enum DataGenerationError: Error {
        case errorGeneratingRandomData
    }
    
    let keyData: String
    let transmissionRiskLevel: Int
    let rollingStartIntervalNumber: Int
    let rollingPeriod: Int
    
    static func createDummy(index: Int) -> TemporaryExposureKey {
        
        // A whole lot of magic numbers here, but this is according to Google's GAEN API specs
        TemporaryExposureKey(
            keyData: randomData(ofLength: 16),
            transmissionRiskLevel: index % 7,
            rollingStartIntervalNumber: 2650847,
            rollingPeriod: 144
        )
    }
    
    static func randomData(ofLength length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status == errSecSuccess {
            return Data(bytes).base64EncodedString()
        }
        else {
            // This should never happen but if random string generation fails,
            // create fixed string for data.
            return "AAAAAAAAAAAAAAAAAAAAAA=="
        }
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

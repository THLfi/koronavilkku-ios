import XCTest
import ExposureNotification
import Combine
@testable import Koronavilkku

class ExposureRepositoryTest: XCTestCase {
    let repository = ExposureRepositoryImpl(exposureManager: MockExposureManager(),
                                            backend: BackendRestApi(config: LocalConfiguration(),
                                                             urlSession: URLSession.shared),
                                            storage: MockFileStorage())

    func testKeyPadding() throws {
        let keys = repository.mapKeysToCorrectLength(enTemporaryExposureKeys: [])
        XCTAssertEqual(keys.count, ExposureRepositoryImpl.keyCount)
    }
    
    func testKeySplicing() throws {
        let keys = (0..<100).map { return createTempKey("foo", $0, $0, 0) }
        let spliced = repository.mapKeysToCorrectLength(enTemporaryExposureKeys: keys)
        XCTAssertEqual(spliced.count, ExposureRepositoryImpl.keyCount)
        spliced.forEach { print($0.rollingStartIntervalNumber) }
    }
    
    func testDoNothing() throws {
        var keys: [ENTemporaryExposureKey] = []
        for _ in 0..<ExposureRepositoryImpl.keyCount {
            keys.append(createTempKey("foo", 0, 0, 0))
        }
        let spliced = repository.mapKeysToCorrectLength(enTemporaryExposureKeys: keys)
        XCTAssertEqual(spliced.count, ExposureRepositoryImpl.keyCount)
        spliced.forEach { print($0.rollingStartIntervalNumber) }
    }
    
    func testWeightedDurations() throws {
        let durations = [180, 360, 720, 1440].map { NSNumber(integerLiteral: $0) }
        XCTAssertEqual(durations.weighted(with: []), [0, 0, 0, 0])
        XCTAssertEqual(durations.weighted(with: [1.0, 0.5, 0.0]), [180, 180, 0, 0])
        XCTAssertEqual(durations.weighted(with: [1.0, 0.5, 0.25]), [180, 180, 180, 0])
        XCTAssertEqual(durations.weighted(with: [1.0, 0.5, 0.25, 0.125]), [180, 180, 180, 180])
        XCTAssertEqual(durations.weighted(with: [1.0, 0.5, 0.25, 0.125, 1.0]), [180, 180, 180, 180])
    }
    
    func testSumSecondsAsMinutes() throws {
        XCTAssertEqual([180.0, 15.0].sumSecondsAsMinutes(), 3)
        XCTAssertEqual([180.0, 55.0].sumSecondsAsMinutes(), 3)
    }
    
    func createTempKey(_ data: String,
                       _ rollingPeriod: ENIntervalNumber,
                       _ rollingStartNumber: ENIntervalNumber,
                       _ riskLevel: ENRiskLevel) -> ENTemporaryExposureKey {
        let ret = ENTemporaryExposureKey()
        ret.keyData = data.data(using: .utf8)!
        ret.rollingPeriod = rollingPeriod
        ret.rollingStartNumber = rollingStartNumber
        ret.transmissionRiskLevel = riskLevel
        
        return ret
    }
}

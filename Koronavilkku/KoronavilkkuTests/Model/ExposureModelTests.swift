import ExposureNotification
import XCTest
@testable import Koronavilkku

class MockExposureInfo : ENExposureInfo {
    private var exposureDate: Date
    private var riskScore: ENRiskScore
    
    init(exposureDate: Date, riskScore: ENRiskScore) {
        self.exposureDate = exposureDate
        self.riskScore = riskScore
    }
    
    override var date: Date {
        exposureDate
    }
    
    override var totalRiskScore: ENRiskScore {
        riskScore
    }
}

class ExposureModelTests: XCTestCase {
    private let config = ExposureConfiguration(minimumRiskScore: 72,
                                               attenuationScores: [],
                                               daysSinceLastExposureScores: [],
                                               durationScores: [],
                                               transmissionRiskScores: [],
                                               durationAtAttenuationThresholds: [],
                                               durationAtAttenuationWeights: [],
                                               exposureRiskDuration: 15,
                                               participatingCountries: ["FI", "NL"])
    
    func testExposureNotificationDates() {
        let exposureDate1 = Date().addingTimeInterval(86_400 * -3)
        let exposureDate2 = Date().addingTimeInterval(86_400 * -7)
        let exposureDate3 = Date().addingTimeInterval(86_400 * -12)

        let details = [
            MockExposureInfo(exposureDate: exposureDate1, riskScore: 50),
            MockExposureInfo(exposureDate: exposureDate2, riskScore: 100),
            MockExposureInfo(exposureDate: exposureDate3, riskScore: 200),
        ]
        
        let detectionTime = Date()
        let notification = details.to(config: config, detectionTime: detectionTime)
        
        XCTAssertEqual(
            notification.detectedOn,
            detectionTime,
            "Should be the current date")
        
        XCTAssertEqual(
            notification.detectionInterval.start,
            Calendar.current.date(byAdding: .day, value: -10, to: detectionTime),
            "The detection interval starts from 10 days ago")
        
        XCTAssertEqual(
            notification.detectionInterval.end,
            Calendar.current.date(byAdding: .day, value: -1, to: detectionTime),
            "The detection interval ends to yesterday")

        // because the exposure date is always UTC midnight, we need to extend it with one day
        // to cover exposures that have happened during the day
        XCTAssertEqual(
            notification.expiresOn,
            Calendar.current.date(byAdding: .day, value: 11, to: exposureDate2),
            "The notification should expire after 10 days from the last detected exposure")

        XCTAssertEqual(notification.exposureCount, 2)
    }
    
    func testLongExposure() {
        let detectionDate = Date()
        let latestExposureDate = Date().addingTimeInterval(86_400 * -2)
        
        let details = [
            MockExposureInfo(exposureDate: Date().addingTimeInterval(86_400 * -14), riskScore: 40),
            MockExposureInfo(exposureDate: Date().addingTimeInterval(86_400 * -5), riskScore: 20),
            MockExposureInfo(exposureDate: latestExposureDate, riskScore: 10),
            MockExposureInfo(exposureDate: Date().addingTimeInterval(86_400 * -9), riskScore: 30),
            MockExposureInfo(exposureDate: Date().addingTimeInterval(86_400 * -20), riskScore: 50),
        ]
        
        let notification = details.to(config: config, detectionTime: detectionDate)

        XCTAssertEqual(
            notification.expiresOn,
            Calendar.current.date(byAdding: .day, value: 11, to: latestExposureDate),
            "The expiration date should be relative to the latest exposure")
        
        XCTAssertEqual(
            notification.exposureCount,
            1,
            "Should count as just one long exposure")
    }
    
    /// No exposures
    ///
    /// This should be an impossible scenario because the EN API should not return an empty set
    /// because we'd never call getExposureInfo() if there aren't exposures to fetch
    func testNoExposures() {
        let detectionDate = Date()
        let details = Array<MockExposureInfo>()
        let notification = details.to(config: config, detectionTime: detectionDate)
        
        // we have no other dates to fix this to
        XCTAssertEqual(
            notification.expiresOn,
            Calendar.current.date(byAdding: .day, value: 11, to: detectionDate),
            "The expiration date should be relative to the detection date")

        XCTAssertEqual(
            notification.exposureCount,
            1,
            "Counts as a long exposure, as we've already notified the user of an exposure")
    }
}

import ExposureNotification
import XCTest
@testable import Koronavilkku

class ExposureModelTests: XCTestCase {

    func testCountExposureNotificationDates() {
        let exposureDate = Date().addingTimeInterval(.day * -7)
        let detectionTime = Date()
        let notification = CountExposureNotification(detectionTime: detectionTime, latestExposureOn: exposureDate, exposureCount: 2)
        
        testCommonExposureNotificationDates(notification, detectionTime, exposureDate)
        XCTAssertEqual(notification.exposureCount, 2)
        
        XCTAssertEqual(
            notification.detectionInterval.end,
            detectionTime.addingTimeInterval(.day * -1),
            "The detection interval ends to yesterday")
    }
    
    func testDaysExposureNotificationDates() {
        let exposureDates = [
            Date().addingTimeInterval(.day * -3),
            Date().addingTimeInterval(.day * -7),
            Date().addingTimeInterval(.day * -12)
        ]
        let latestExposure = exposureDates[0]

        let detectionTime = Date()
        let notification = DaysExposureNotification(detectedOn: detectionTime, exposureDays: exposureDates)
        
        testCommonExposureNotificationDates(notification, detectionTime, latestExposure)
        XCTAssertEqual(notification.dayCount, exposureDates.count)
        
        XCTAssertEqual(
            notification.detectionInterval.end,
            detectionTime,
            "The detection interval ends to yesterday")
    }
    
    private func testCommonExposureNotificationDates(_ notification: ExposureNotification, _ detectionTime: Date, _ latestExposure: Date) {
        XCTAssertEqual(
            notification.detectedOn,
            detectionTime,
            "Should be the current date")
        
        XCTAssertEqual(
            notification.detectionInterval.start,
            detectionTime.addingTimeInterval(.day * -14),
            "The detection interval starts from 14 days ago")

        // because the exposure date is always UTC midnight, we need to extend it with one day
        // to cover exposures that have happened during the day
        XCTAssertEqual(
            notification.expiresOn,
            latestExposure.addingTimeInterval(.day * 15),
            "The notification should expire after 14 days from the last detected exposure")
        
        XCTAssertEqual(notification.latestExposureDate, latestExposure)
    }
}

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
    }
    
    private func testCommonExposureNotificationDates(_ notification: ExposureNotification, _ detectionTime: Date, _ latestExposure: Date) {
        XCTAssertEqual(
            notification.detectedOn,
            detectionTime,
            "Should be the current date")
        
        XCTAssertEqual(
            notification.detectionInterval.start,
            Calendar.current.date(byAdding: .day, value: -14, to: detectionTime),
            "The detection interval starts from 14 days ago")
        
        XCTAssertEqual(
            notification.detectionInterval.end,
            Calendar.current.date(byAdding: .day, value: -1, to: detectionTime),
            "The detection interval ends to yesterday")

        // because the exposure date is always UTC midnight, we need to extend it with one day
        // to cover exposures that have happened during the day
        XCTAssertEqual(
            notification.expiresOn,
            Calendar.current.date(byAdding: .day, value: 15, to: latestExposure),
            "The notification should expire after 14 days from the last detected exposure")
        
        XCTAssertEqual(notification.latestExposureDate, latestExposure)
    }
}

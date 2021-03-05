@testable import Koronavilkku
import XCTest

class MockNotificationService : NotificationService {
    var isEnabled = true
    var ensureProvisionalRequest: Bool?
    
    func requestAuthorization(provisional: Bool, completion: StatusCallback?) {
        if let provisionalCheck = ensureProvisionalRequest {
            XCTAssertEqual(provisionalCheck, provisional, "Provisional argument does not match ensured value")
        }
        
        completion?(isEnabled)
    }
    
    func isEnabled(completion: @escaping StatusCallback) {
        completion(isEnabled)
    }
    
    var showExposureNotificationLog = [(exposureCount: Int?, delay: TimeInterval?)]()
    
    func showExposureNotification(exposureCount: Int?, delay: TimeInterval?) {
        showExposureNotificationLog.append((exposureCount, delay))
    }
    
    var hideBadgeCalled = 0
    
    func hideBadge() {
        hideBadgeCalled += 1
    }
}

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
    
    var showNotificationLog = [(title: String, body: String, delay: TimeInterval?, badgeNumber: Int?)]()
    
    func showNotification(title: String, body: String, delay: TimeInterval?, badgeNumber: Int?) {
        showNotificationLog.append((title, body, delay, badgeNumber))
    }
    
    var hideBadgeCalled = 0
    
    func hideBadge() {
        hideBadgeCalled += 1
    }
}

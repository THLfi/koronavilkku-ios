import UIKit
import Foundation
import UserNotifications

protocol NotificationService {
    typealias StatusCallback = ((_ enabled: Bool) -> Void)
    
    func isEnabled(completion: @escaping StatusCallback)
    func requestAuthorization(provisional: Bool, completion: StatusCallback?)
    func showNotification(title: String, body: String, delay: TimeInterval?, badgeNumber: Int?)
    func updateBadgeNumber(_ number: Int?)
}

struct NotificationServiceImpl : NotificationService {
    /// The optional completion closure is called with the same enabled value as `isEnabled` does.
    func requestAuthorization(provisional: Bool = false, completion: StatusCallback? = nil) {
        let center = UNUserNotificationCenter.current()
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]

        if provisional {
            options.insert(.provisional)
        }
        
        center.requestAuthorization(options: options) { granted, error in
            
            if let error = error {
                Log.e("Error requesting notification authorization: \(error)")
            } else {
                Log.d("Notification authorization granted: \(granted)")
            }
            
            if let completion = completion {
                isEnabled(completion: completion)
            }
        }
    }

    /// Determines whether the user has notifications turned on or not
    ///
    /// Calls the completion handler with the notifications enabled status. We're only considering
    /// authorized notifications as being enabled, even if the user has not turned off provisional
    /// notifications. We could tighten this even further by requiring specific notification types,
    /// but that should be very carefully communicated to the user.
    func isEnabled(completion: @escaping StatusCallback) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func showNotification(title: String, body: String, delay: TimeInterval? = nil, badgeNumber: Int? = nil) {
        let center = UNUserNotificationCenter.current()

        let doRequest = {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            if let badgeNumber = badgeNumber {
                content.badge = NSNumber(value: badgeNumber)
            }

            let uuid = UUID().uuidString
            var trigger: UNTimeIntervalNotificationTrigger? = nil
            
            if let delay = delay {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            }
            
            let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)

            center.add(request) { (error) in
                if let error = error {
                    Log.e("Failed to display a local notification: \(error)")
                }
            }
        }
        
        center.getNotificationSettings { settings in

            // One could simply request provisional authorization in application(didFinishLaunchingWithOptions:), but
            // it can lead less visible notifications: when user is asked for permission to display notifications and
            // user doesn't grant permission, then user is presented with instructions to go to settings to enable notifications
            // => user does that => only the Notification Center setting is enabled, i.e. the notification would be as
            // visible as with provisional authorization. If no provisional authorization has been asked, then
            // all settings will be enabled when user enables notifications (after having denied permission).
            // Therefore request provisional authorization only when it is actually needed.
            switch settings.authorizationStatus {
            case .notDetermined:
                requestAuthorization(provisional: true) { _ in
                    doRequest()
                }
            
            case .authorized, .provisional:
                doRequest()
            
            default:
                Log.d("Unauthorized to display notifications")
            }
        }
    }
    
    func updateBadgeNumber(_ number: Int?) {
        UIApplication.shared.applicationIconBadgeNumber = number ?? 0
    }
}

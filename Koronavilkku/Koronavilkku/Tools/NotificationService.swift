import UIKit
import Foundation
import UserNotifications

protocol NotificationService {
    typealias StatusCallback = ((_ enabled: Bool) -> Void)
    
    func requestAuthorization(provisional: Bool, completion: StatusCallback?)
    func isEnabled(completion: @escaping StatusCallback)
    func showExposureNotification(exposureCount: Int?, delay: TimeInterval?)
    func hideBadge()
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
    
    func isEnabled(completion: @escaping (_ enabled: Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.notificationsEnabled())
            }
        }
    }
    
    func showExposureNotification(exposureCount: Int?, delay: TimeInterval? = nil) {
        showNotification(title: Translation.ExposureNotificationTitle.localized,
                         body: Translation.ExposureNotificationBody.localized,
                         delay: delay,
                         badgeNumber: exposureCount)
    }

    private func showNotification(title: String, body: String, delay: TimeInterval? = nil, badgeNumber: Int? = nil) {
        let center = UNUserNotificationCenter.current()

        func doRequest() {
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
            if settings.authorizationStatus == .notDetermined {
                requestAuthorization(provisional: true) { _ in
                    doRequest()
                }
                
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                doRequest()

            } else {
                Log.d("Unauthorized to display notifications")
            }
        }
    }
    
    func hideBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

extension UNNotificationSettings {
  
    /// Returns `true` if notifications are enabled from this app's perspective.
    func notificationsEnabled() -> Bool {
        // .authorized is required so that the user reacts to the "enable notifications" state in main view (or in a notification
        // shown with provisional authorization). For the latter condition the intent is to have a setting that would increase
        // the likelihood of the user reacting to the notification at some point
        return authorizationStatus == .authorized && (notificationCenterSetting == .enabled || badgeSetting == .enabled)
    }
}

import Combine
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var activationTask: AnyCancellable?
    var configurationTask: AnyCancellable?
    var endOfLifeTask: AnyCancellable?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            // Set every UILabel automatically respond to Dynamic Type changes
            UILabel.appearance().adjustsFontForContentSizeCategory = true
            
            switch true {
            case Environment.default.exposureRepository.isEndOfLife:
                window.rootViewController = EndOfLifeViewController()
                
            case !LocalStore.shared.isOnboarded:
                window.rootViewController = OnboardingViewController()
                
            default:
                window.rootViewController = RootViewController()
            }
            
            self.window = window
            window.makeKeyAndVisible()
            
            // Check if user activity contains browsing action
            if let activity = connectionOptions.userActivities
                .filter({ $0.activityType == NSUserActivityTypeBrowsingWeb })
                .first,
               let code = extractCode(userActivity: activity) {
                openCodeView(using: code)
            }
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Get URL components from the incoming user activity
        guard let code = extractCode(userActivity: userActivity) else {
            Log.d("Invalid code")
            return
        }
        
        openCodeView(using: code)
    }
    
    func openCodeView(using code: String) {
        (window?.rootViewController as? RootViewController)?.openReportInfectionScreenWithCode(code: code)
    }
    
    func extractCode(userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.query,
              let _ = UInt64(code) else { return nil }
        return code
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        let exposureRepository = Environment.default.exposureRepository
        
        guard !exposureRepository.isEndOfLife else { return }

        // Detect when the end of life has been reached an update the UI accordingly
        endOfLifeTask = exposureRepository.onEndOfLife
            .receive(on: RunLoop.main)
            .sink { _ in
                self.window?.rootViewController = EndOfLifeViewController()
            }
        
        // Fetch configuration to refresh the EFGS country list and end of life data
        configurationTask = exposureRepository.getConfiguration()
            .sink { _ in } receiveValue: { config in
                Environment.default.efgsRepository.updateCountryList(from: config)
            }
        
        activationTask = ExposureManagerProvider.shared.activated.sink { activated in
            exposureRepository.refreshStatus()
        }

        exposureRepository.removeExpiredExposures()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    //MARK: UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Needed to display the notification even if the app is in foreground.
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        (window?.rootViewController as? RootViewController)?.openHomeScreen()
        completionHandler()
    }
}


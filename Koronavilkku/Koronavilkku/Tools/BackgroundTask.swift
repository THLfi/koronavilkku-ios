import BackgroundTasks
import Combine
import ExposureNotification

enum TaskType {
    case notifications
    case dummyPost
}

class BackgroundTaskManager {
    
    static let shared = BackgroundTaskManager()
    
    func registerTasks() {
        register(for: .notifications)
        register(for: .dummyPost)
    }
    
    func scheduleTasks() {
        schedule(for: .notifications)
        schedule(for: .dummyPost)
    }
    
    private func schedule(for type: TaskType) {
        switch type {
        case .notifications:
            BackgroundTaskForNotifications.shared.schedule()
        case .dummyPost:
            BackgroundTaskForDummyPosting.shared.schedule()
        }
    }
    
    private func register(for type: TaskType) {
        switch type {
        case .notifications:
            BackgroundTaskForNotifications.shared.register()
        case .dummyPost:
            BackgroundTaskForDummyPosting.shared.register()
        }
    }
    
    func identifier(for type: TaskType) -> String {
        switch type {
        case .notifications:
            return BackgroundTaskForNotifications.shared.identifier
        case .dummyPost:
            return BackgroundTaskForDummyPosting.shared.identifier
        }
    }
}

protocol BackgroundTask {
    
    static var shared: BackgroundTask { get }
    var type: TaskType { get }
    var identifier: String { get }
    func register()
    func schedule()
    
}

final class BackgroundTaskForNotifications: BackgroundTask {
    
    static let shared: BackgroundTask = BackgroundTaskForNotifications()
    let type: TaskType = .notifications
    var identifier: String = Bundle.main.bundleIdentifier! + ".exposure-notification"
    
    private var backgroundTask: AnyCancellable?
    
    // ENAPIVersion 2 detectExposures() limited to 6 calls per day
    // we're not using it yet, but it's a good starting point
    let TASK_MINIMUM_DELAY: TimeInterval = 4 * 60 * 60
    
    // To test the background tasks (this does not work on simulator, apparently)
    // 1. Pause the debugger after registering the task
    // 2. Type to the lldb console
    //    `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fi.thl.koronahaavi.exposure-notification"]`
    // 3. Resume the debugger
    func register() {
        Log.d("Register background task for notifications")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            Log.d("Run background task for notifications")

            // reschedule first to prevent unexpected errors from breaking the chain
            self.schedule()

            Log.d("Authorized: \(ENManager.authorizationStatus == .authorized)")
            guard ENManager.authorizationStatus == .authorized else {
                return task.setTaskCompleted(success: true)
            }

            self.backgroundTask = BackgroundTaskForNotifications.execute { success in
                task.setTaskCompleted(success: success)
            }
        }
    }
    
    func schedule() {
        Log.d("Schedule task for notifications")
        let taskRequest = BGProcessingTaskRequest(identifier: identifier)
        taskRequest.requiresNetworkConnectivity = true
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: TASK_MINIMUM_DELAY)
        do {
            Log.d("Try to schedule new task \(taskRequest)")
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            Log.e("Unable to schedule background task: \(error.localizedDescription)")
        }
    }
    
    static func execute(_ completionHandler: @escaping (Bool) -> Void) -> AnyCancellable {
        let batchRepository = Environment.default.batchRepository
        let exposureRepository = Environment.default.exposureRepository
        let municipalityRepository = Environment.default.municipalityRepository
        
        // run all required async tasks concurrently
        return Publishers.Zip3(
            // 1. download new batches from the backend
            batchRepository.getNewBatches().collect(),
            
            // 2. fetch the up-to-date risk parameter configuration
            exposureRepository.getConfiguration(),
            
            // 3. update the municipality list to mask the traffic from exposure notifications
            municipalityRepository.updateMunicipalityList().catch { _ in
                // …but prevent possible errors from interfering with the real background task
                return Empty(completeImmediately: true)
            }
        ).flatMap { (ids, config, _) -> (AnyPublisher<Bool, Error>) in
            DispatchQueue.main.async {
                LocalStore.shared.removeExpiredExposures()
            }
            
            Log.d("Got \(ids.count) keys")
            if ids.count == 0 {
                Log.d("No new batches to check")
                return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            
            Log.d("Received batches and configurations. Now detect exposures")
            return exposureRepository.detectExposures(ids: ids, config: config)
        }
        .sink(
            receiveCompletion: {
                // Update last checked date once we have tried loading batches
                LocalStore.shared.updateDateLastPerformedExposureDetection()
                
                exposureRepository.deleteBatchFiles()
                
                switch $0 {
                case .finished:
                    Log.d("Detecting exposures finished")
                    completionHandler(true)
                case .failure(let error):
                    Log.e("Detecting exposures failed: \(error.localizedDescription)")
                    completionHandler(false)
                }
            },
            receiveValue: { exposuresFound in
                Log.d("Detecting exposures succeeded. Exposures found: \(exposuresFound)")
            }
        )
    }
}

fileprivate final class BackgroundTaskForDummyPosting: BackgroundTask {
    
    static let shared: BackgroundTask = BackgroundTaskForDummyPosting()
    let type: TaskType = .dummyPost
    var identifier: String = Bundle.main.bundleIdentifier! + ".dummy-post"
    
    private var backgroundTask: AnyCancellable?
    private var exposureRepository = Environment.default.exposureRepository
    
    // To test the background tasks (this does not work on simulator, apparently)
    // 1. Pause the debugger after registering the task
    // 2. Type to the lldb console
    //    `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fi.thl.koronahaavi.dummy-post"]`
    // 3. Resume the debugger
    func register() {
        Log.d("Register background task for dummy posting")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            Log.d("Run background task for dummy posting")

            // reschedule first to prevent unexpected errors from breaking the chain
            self.schedule()
            
            self.backgroundTask = self.exposureRepository.postDummyKeys()
                .sink(receiveCompletion: {
                    switch $0 {
                    case .finished:
                        Log.d("Dummy posting finished")
                        task.setTaskCompleted(success: true)
                    case .failure(let error):
                        Log.e("Dummy posting failed \(error.localizedDescription)")
                        task.setTaskCompleted(success: false)
                    }
                },
                receiveValue: { _ in }
                )}
    }
    
    func schedule() {
        Log.d("Schedule task for dummy posting")
        let taskRequest = BGProcessingTaskRequest(identifier: identifier)
        taskRequest.requiresNetworkConnectivity = true
        taskRequest.requiresExternalPower = false
        let randomHours = Double.random(in: 12...24)
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * randomHours)
        do {
            Log.d("Try schedule new task \(taskRequest)")
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            Log.e("Unable to schedule background task: \(error.localizedDescription)")
        }
    }
}

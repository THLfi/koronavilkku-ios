import BackgroundTasks
import Combine
import ExposureNotification
import UIKit

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
    
    associatedtype Task: BackgroundTask
    static var shared: Task { get }
    var type: TaskType { get }
    var identifier: String { get }
    func register()
    func schedule()
    
}

final class BackgroundTaskForNotifications: BackgroundTask {
    static var shared = BackgroundTaskForNotifications()
    let type: TaskType = .notifications
    var identifier: String = Bundle.main.bundleIdentifier! + ".exposure-notification"
    
    private var backgroundTask: AnyCancellable?

    @Published
    private(set) var detectionRunning = false

    // ENAPIVersion 2 detectExposures() limited to 6 calls per day
    // we're not using it yet, but it's a good starting point
    let TASK_MINIMUM_DELAY: TimeInterval = .hours(4)
    
    // To test the background tasks (this does not work on simulator, apparently)
    // 1. Pause the debugger after registering the task
    // 2. Type to the lldb console
    //    `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fi.thl.koronahaavi.exposure-notification"]`
    // 3. Resume the debugger
    func register() {
        Log.d("Register background task for notifications")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            Log.d("Run background task for notifications")
            
            guard !Environment.default.exposureRepository.isEndOfLife else {
                return task.setTaskCompleted(success: true)
            }
            
            // reschedule first to prevent unexpected errors from breaking the chain
            self.schedule()

            Log.d("Authorized: \(ENManager.authorizationStatus == .authorized)")
            guard ENManager.authorizationStatus == .authorized else {
                return task.setTaskCompleted(success: true)
            }

            self.execute { success in
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
    
    func run() -> AnyPublisher<Bool, Never> {
        var backgroundId: UIBackgroundTaskIdentifier! = nil
        
        backgroundId = UIApplication.shared.beginBackgroundTask() { [weak self] in
            self?.backgroundTask?.cancel()
            UIApplication.shared.endBackgroundTask(backgroundId)
        }
        
        return Future { promise in
            self.execute { success in
                UIApplication.shared.endBackgroundTask(backgroundId)
                promise(.success(success))
            }
        }.setFailureType(to: Never.self).eraseToAnyPublisher()
    }

    private func execute(_ completionHandler: @escaping (Bool) -> Void) {
        let batchRepository = Environment.default.batchRepository
        let exposureRepository = Environment.default.exposureRepository
        let municipalityRepository = Environment.default.municipalityRepository
        let efgsRepository = Environment.default.efgsRepository
        
        // prevent running checks in parallel
        self.backgroundTask?.cancel()
        self.detectionRunning = true
        
        // always remove expired exposures to keep the badge number up-to-date
        exposureRepository.removeExpiredExposures()

        // run all required async tasks concurrently
        self.backgroundTask = Publishers.Zip3(
            // 1. download new batches from the backend
            batchRepository.getNewBatches().collect(),
            
            // 2. fetch the up-to-date risk parameter configuration
            exposureRepository.getConfiguration(),
            
            // 3. update the municipality list to mask the traffic from exposure notifications
            municipalityRepository.updateMunicipalityList().catch { _ in
                // …but prevent possible errors from interfering with the real background task
                return Empty(completeImmediately: true)
            }
        )
        .receive(on: RunLoop.main)
        .flatMap { (ids, config, _) -> (AnyPublisher<Bool, Error>) in
            Log.d("Updating the EFGS country list from the configuration")
            efgsRepository.updateCountryList(from: config)
            
            if ids.count == 0 {
                Log.d("No new batches to check")
                return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            
            Log.d("Received \(ids.count) new batches, detecting exposures…")
            return exposureRepository.detectExposures(ids: ids, config: config)
        }
        .sink(
            receiveCompletion: {
                exposureRepository.deleteBatchFiles()
                
                if case .failure(let error) = $0 {
                    Log.e("Detecting exposures failed: \(error.localizedDescription)")
                    completionHandler(false)
                }
                
                self.detectionRunning = false
            },
            receiveValue: { exposuresFound in
                Log.d("Detecting exposures succeeded. Exposures found: \(exposuresFound)")
                LocalStore.shared.updateDateLastPerformedExposureDetection()
                completionHandler(true)
            }
        )
    }
}

fileprivate final class BackgroundTaskForDummyPosting: BackgroundTask {
    
    static let shared = BackgroundTaskForDummyPosting()
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

            guard !Environment.default.exposureRepository.isEndOfLife else {
                return task.setTaskCompleted(success: true)
            }
            
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
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: .hours(randomHours))
        do {
            Log.d("Try schedule new task \(taskRequest)")
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            Log.e("Unable to schedule background task: \(error.localizedDescription)")
        }
    }
}

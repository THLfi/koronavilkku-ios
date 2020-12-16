import UIKit
import SnapKit
import Foundation
import BackgroundTasks
import Combine
import ExposureNotification

class TestViewController: UIViewController {
    let batchIdInput = UITextField()
    
    var tasks = [AnyCancellable]()
    
    lazy var storeBatchIdButton = self.createButton(title: "Store batch id", action: #selector(storeBatchId))
    lazy var testBatchDownloadButton = self.createButton(title: "Test batch loading", action: #selector(batchDownloadPressed))
    lazy var testBatchDownloadInTheBackgroundButton = self.createButton(title: "Test background batch", action: #selector(batchDownloadBackgroundPressed))
    lazy var downloadAndDetectButton = self.createButton(title: "Dl and detect", action: #selector(downloadAndDetect))
    lazy var addExposureButton = self.createButton(title: "Add exposure", action: #selector(addExposure))
    lazy var addExposureDelayedButton = self.createButton(title: "Add exposure, delayed", action: #selector(addExposureDelayed))
    lazy var addLegacyExposureButton = self.createButton(title: "Add legacy exposure", action: #selector(addLegacyExposure))
    lazy var removeExposuresButton = self.createButton(title: "Remove exposures", action: #selector(removeExposures))
    lazy var radarStatus = self.createButton(title: "Radar status \(LocalStore.shared.uiStatus)", action: #selector(toggleRadarStatus))
    lazy var resetOnboardingButton = self.createButton(title: "Reset onboarding", action: #selector(resetOnboarding))
    lazy var showExposureLogsButton = self.createButton(title: "Exposure logs", action: #selector(showExposureLogs))
    lazy var updateMunicipalityListButton = self.createButton(title: "Update municipality list", action: #selector(updateMunicipalityList))
    lazy var setLastExposureCheckButton = self.createButton(title: "Set exposure check date", action: #selector(setLastExposureCheck))
    lazy var dumpEFGSCountriesButton = self.createButton(title: "Dump EFGS countries", action: #selector(dumpEFGSCountries))
    
    // force downcast, because we're using the internals here
    var batchRepository = Environment.default.batchRepository as! BatchRepositoryImpl
    var exposureManager = ExposureManagerProvider.shared.manager
    var exposureRepository = Environment.default.exposureRepository
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addKeyboardDisposer()
        
        title = "Tester"
        view.backgroundColor = .white
        
        self.view.addKeyboardDisposer()
        
        view.addSubview(batchIdInput)
        batchIdInput.placeholder = "Batch id"
        batchIdInput.borderStyle = .bezel
        batchIdInput.textColor = .black
        batchIdInput.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(30)
            make.right.equalTo(view.snp.centerX)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        }
        
        view.addSubview(storeBatchIdButton)
        self.storeBatchIdButton.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(30)
            make.left.equalTo(batchIdInput.snp.right).offset(10)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        }
        
        var top = batchIdInput.snp.bottom
        
        func appendButton(_ button: UIButton) {
            self.view.addSubview(button)
            button.snp.makeConstraints { make in
                make.width.equalTo(200)
                make.height.equalTo(30)
                make.centerX.equalToSuperview()
                make.top.equalTo(top).offset(20)
            }
            top = button.snp.bottom
        }
        
        appendButton(testBatchDownloadButton)
        appendButton(downloadAndDetectButton)
        appendButton(testBatchDownloadInTheBackgroundButton)
        appendButton(addExposureButton)
        appendButton(addExposureDelayedButton)
        appendButton(addLegacyExposureButton)
        appendButton(removeExposuresButton)
        appendButton(radarStatus)
        appendButton(resetOnboardingButton)
        appendButton(showExposureLogsButton)
        appendButton(updateMunicipalityListButton)
        appendButton(setLastExposureCheckButton)
        appendButton(dumpEFGSCountriesButton)
        
        LocalStore.shared.$uiStatus.addObserver(using: { [weak self] in
            self?.radarStatus.setTitle("Radar status \(LocalStore.shared.uiStatus)", for: .normal)
        })
    }
    
    @objc func storeBatchId() {
        LocalStore.shared.nextDiagnosisKeyFileIndex = batchIdInput.text
        Log.d("Stored batchId \(String(describing: batchIdInput.text))")
    }
    
    @objc func batchDownloadPressed() {
        batchRepository.getNewBatches()
            .sink(
                receiveCompletion: {
                    switch ($0) {
                    case .failure(let error):
                        Log.e("batchDownloadPressed error \(error)")
                    case .finished:
                        Log.d("batchDownloadPressed Finished")
                    }
                    Environment.default.exposureRepository.deleteBatchFiles()
                },
                receiveValue: { id in
                    Log.d("Received urls: \(id)")
                }
            )
            .store(in: &tasks)
    }
    
    @objc func downloadAndDetect() {
        BackgroundTaskForNotifications.shared.run()
            .sink { success in
                if success {
                    Log.d("Download and detect completed successfully")
                } else {
                    Log.e("Failed to download and detect")
                }
            }.store(in: &tasks)
    }
    
    @objc func batchDownloadBackgroundPressed() {
        let taskRequest = BGProcessingTaskRequest(identifier: BackgroundTaskManager.shared.identifier(for: .notifications))
        taskRequest.requiresNetworkConnectivity = true
        do {
            Log.d("Submitting background task")
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            Log.e("Could not schedule batch download: \(error)")
        }
    }
    
    @objc func addExposure() {
        addTestExposure()
    }
    
    @objc func addLegacyExposure() {
        let exposure = Exposure(date: Date())
        LocalStore.shared.exposures.append(exposure)
        Log.d("Created exposure \(exposure)")
    }

    @objc func addExposureDelayed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.addTestExposure()
        }
    }
    
    private func addTestExposure() {
        let notification = ExposureNotification(detectionTime: Date(),
                                                latestExposureOn: Date().addingTimeInterval(86_400 * -3),
                                                exposureCount: Int.random(in: 1...5))
        
        LocalStore.shared.exposureNotifications.append(notification)
        LocalStore.shared.updateDateLastPerformedExposureDetection()
        Log.d("Created exposure notification \(notification)")
    }
    
    @objc func removeExposures() {
        LocalStore.shared.resetExposures()
    }
    
    @objc func toggleRadarStatus() {
        let nextStatus = self.nextStatus()
        
        if let manager = ExposureManagerProvider.shared.manager as? MockExposureManager {
            manager.systemDisabled = nextStatus == .apiDisabled
        }
        
        switch nextStatus {
        case .off:
            exposureRepository.setStatus(enabled: false)
        case .on:
            exposureRepository.setStatus(enabled: true)
        default:
            // Other cases are simulated ones.
            LocalStore.shared.uiStatus = nextStatus
        }
    }
    
    @objc func resetOnboarding() {
        LocalStore.shared.isOnboarded = false
    }
    
    @objc func showExposureLogs() {
        let exposureLogs = ExposureLogsViewController()
        self.present(exposureLogs, animated: true)
    }
    
    @objc func updateMunicipalityList() {
        Environment.default.municipalityRepository.updateMunicipalityList()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        self.showDialog("Failed to update municipality list, error: \(error)")
                    case .finished:
                        self.showDialog("Updated municipality list successfully", title: "")
                    }
                }, receiveValue: { _ in }
            )
            .store(in: &tasks)
    }
    
    @objc func setLastExposureCheck() {
        LocalStore.shared.$dateLastPerformedExposureDetection.wrappedValue = Date().addingTimeInterval(30 - ExposureRepositoryImpl.manualCheckThreshold)
    }
    
    @objc func dumpEFGSCountries() {
        showDialog(
            Environment.default.efgsRepository.getParticipatingCountries()?
                .map { $0.localizedName }
                .joined(separator: "\n") ?? "",
            title: "EFGS Countries")
    }
    
    private func showDialog(_ message: String, title: String = "Error") {
        showAlert(title: title, message: message, buttonText: "Dismiss")
    }
    
    private func nextStatus() -> RadarStatus {
        let currentStatus = LocalStore.shared.uiStatus
        switch currentStatus {
        case .on:
            return .off
        case .off:
            return .locked
        case .locked:
            return .btOff
        case .btOff:
            return .apiDisabled
        case .apiDisabled:
            return .on
        }
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.Greyscale.white, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.backgroundColor = UIColor.Greyscale.darkGrey
        button.layer.cornerRadius = 10
        return button
    }
}

#if DEBUG

import SwiftUI

struct BatchDownloadTesterViewController_Preview: PreviewProvider {
    static var previews: some View = createPreview(for: TestViewController())
}

#endif

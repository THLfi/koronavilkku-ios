import Foundation
import UIKit
import SnapKit
import Combine

class ExposuresViewController: UIViewController {
    
    enum Text : String, Localizable {
        case TitleHasExposures
    }

    private let exposureRepository: ExposureRepository
    private let exposuresViewWrapper = ExposuresViewWrapper()
    private var updateTasks = Set<AnyCancellable>()
    
    private var exposureStatus: ExposureStatus? {
        didSet {
            guard let exposureStatus = exposureStatus, exposureStatus != oldValue else { return }
            self.updateNavigationBar()
            self.exposuresViewWrapper.exposureStatus = exposureStatus
        }
    }
    
    private let button = UIButton()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            if case .exposed = exposureStatus {
                return .lightContent
            }
            
            return .darkContent
        }
    }
    
    init(env: Environment = .default) {
        exposureRepository = env.exposureRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exposuresViewWrapper.delegate = self
        initUI()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setDefaultStyle()
        super.viewWillDisappear(animated)
    }
    
    private func bindViewModel() {
        exposureRepository.exposureStatus()
            .receive(on: RunLoop.main)
            .sink { [weak self] exposureStatus in
                self?.exposureStatus = exposureStatus
            }
            .store(in: &updateTasks)
        
        exposureRepository.detectionStatus()
            .receive(on: RunLoop.main)
            .sink { [weak self] detectionStatus in
                self?.exposuresViewWrapper.detectionStatus = detectionStatus
            }
            .store(in: &updateTasks)
        
        exposureRepository.timeFromLastCheck()
            .sink { [weak self] time in
                self?.exposuresViewWrapper.timeFromLastCheck = time
            }
            .store(in: &updateTasks)
    }
    
    private func updateNavigationBar() {
        guard let navController = navigationController else {
            return
        }
        
        let appearance = navController.navigationBar.standardAppearance.copy()
        navController.navigationBar.prefersLargeTitles = false

        if case .exposed = exposureStatus {
            navigationItem.title = Text.TitleHasExposures.localized
            appearance.backgroundColor = UIColor.Primary.red
            appearance.titleTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.Greyscale.white
            navController.navigationBar.tintColor = UIColor.Greyscale.white
        } else {
            navigationItem.title = ""
            appearance.backgroundColor = UIColor.Secondary.blueBackdrop
            appearance.titleTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.Greyscale.black
            navController.navigationBar.tintColor = UIColor.Primary.blue
        }
        
        navController.navigationBar.standardAppearance = appearance
        navController.setNavigationBarHidden(false, animated: false)
        navController.navigationBar.setNeedsLayout()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func initUI() {
        view.removeAllSubviews()
        
        let margins = UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
        let contentView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: margins)
        contentView.addSubview(exposuresViewWrapper)
        exposuresViewWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ExposuresViewController: ExposuresViewDelegate {
    func startManualCheck() {
        BackgroundTaskForNotifications.shared.run()
            .receive(on: RunLoop.main)
            .sink { [weak self] success in
                if !success {
                    self?.showAlert(title: Translation.ManualCheckErrorTitle.localized,
                                    message: Translation.ManualCheckErrorMessage.localized,
                                    buttonText: Translation.ManualCheckErrorButton.localized)
                }
            }
            .store(in: &updateTasks)
    }
    
    func showHowItWorks() {
        self.navigationController?.present(HowItWorksViewController(), animated: true)
    }
    
    func makeContact() {
        self.navigationController?.pushViewController(SelectMunicipalityViewController(style: .grouped), animated: true)
    }

    func showNotificationList() {
        self.navigationController?.pushViewController(UIViewController(), animated: true)
    }
}


#if DEBUG
import SwiftUI

struct ExposuresViewControllerPreview: PreviewProvider {
    static var previews: some View = Group {
        createPreviewInNavController(for: ExposuresViewController(env: .preview {
            .init(exposureStatus: .init(.unexposed))
        }))

        createPreviewInNavController(for: ExposuresViewController(env: .preview {
        .init(exposureStatus: .init(.exposed(notificationCount: nil)))
        }))
    }
}
#endif

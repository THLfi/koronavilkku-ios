import Foundation
import UIKit
import SnapKit
import Combine

protocol ExposuresViewDelegate: AnyObject {
    func showHowItWorks()
    func showExposureGuide()
    func makeContact()
    func startManualCheck()
    func showNotificationList()
}

class ExposuresView : UIView {
    weak var delegate: ExposuresViewDelegate?
}

class ExposuresViewController: UIViewController {
    
    enum Text : String, Localizable {
        case TitleHasExposures
    }

    private let exposureRepository: ExposureRepository
    private var updateTasks = Set<AnyCancellable>()
    private var exposuresView: ExposuresView!
    private var containerView: UIView!
        
    private var exposureStatus: ExposureStatus? {
        didSet {
            guard let exposureStatus = exposureStatus,
                  exposureStatus != oldValue else { return }
            
            self.updateNavigationBar()
            self.render()
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
                if let noExposuresView = self?.exposuresView as? NoExposuresView {
                    noExposuresView.detectionStatus = detectionStatus
                }
            }
            .store(in: &updateTasks)
        
        exposureRepository.timeFromLastCheck()
            .sink { [weak self] time in
                if let noExposuresView = self?.exposuresView as? NoExposuresView {
                    noExposuresView.timeFromLastCheck = time
                }
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
        let margins = UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
        
        containerView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop, margins: margins)
        
        render()
    }
    
    private func render() {
        containerView.removeAllSubviews()
        
        if case .exposed(let notificationCount) = exposureStatus {
            exposuresView = HasExposuresView(notificationCount: notificationCount)
        } else {
            exposuresView = NoExposuresView()
        }
        
        exposuresView.delegate = self
        containerView.addSubview(exposuresView)
        exposuresView.snp.makeConstraints { make in
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
    
    func showExposureGuide() {
        self.navigationController?.present(ExposureGuideViewController(), animated: true)
    }
    
    func showHowItWorks() {
        self.navigationController?.showGuide()
    }
    
    func makeContact() {
        self.navigationController?.pushViewController(SelectMunicipalityViewController(style: .grouped), animated: true)
    }

    func showNotificationList() {
        self.navigationController?.present(NotificationListViewController(), animated: true)
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

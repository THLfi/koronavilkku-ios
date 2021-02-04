import Combine
import SnapKit
import UIKit

class MainViewController: UIViewController, LocalizedView {
    enum Text : String, Localizable {
        case ProtectionButtonTitle
        case ProtectionButtonURL
        case SituationButtonTitle
        case SituationButtonURL
        case AppGuideButton
    }
    
    private var headerView: StatusHeaderView!
    
    private var exposuresElement: ExposuresElement!
    private var exposuresElementTopConstraint: Constraint!
    private var exposuresElementBottomConstraint: Constraint!
    
    private var symptomsElement: SymptomsElement!
    private var symptomsElementTopConstraint: Constraint!
    private var symptomsElementBottomConstraint: Constraint!

    private var tasks = Set<AnyCancellable>()
    private let exposureRepository: ExposureRepository
    
    init(env: Environment = .default) {
        self.exposureRepository = env.exposureRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        createUI()
        initDataBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar from view as we have no need for it in main view
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // restart animation
        self.headerView?.render()
    }
    
    private func initDataBindings() {
        exposureRepository.detectionStatus()
            .combineLatest(exposureRepository.exposureStatus(),
                           exposureRepository.timeFromLastCheck())
            .sink { [weak self] detectionStatus, exposureStatus, timeFromLastCheck in
                guard let self = self else { return }

                if detectionStatus.status == .locked {
                    self.exposuresElement.isHidden = true
                    self.exposuresElementTopConstraint.deactivate()
                    self.exposuresElementBottomConstraint.deactivate()
                } else {
                    self.exposuresElement.isHidden = false
                    self.exposuresElementTopConstraint.activate()
                    self.exposuresElementBottomConstraint.activate()

                    self.exposuresElement.detectionStatus = detectionStatus
                    self.exposuresElement.exposureStatus = exposureStatus
                    self.exposuresElement.timeFromLastUpdate = timeFromLastCheck
                }
                
                if case .exposed = exposureStatus, detectionStatus.status != .locked {
                    self.symptomsElement.isHidden = true
                    self.symptomsElementTopConstraint.deactivate()
                    self.symptomsElementBottomConstraint.deactivate()
                } else {
                    self.symptomsElement.isHidden = false
                    self.symptomsElementTopConstraint.activate()
                    self.symptomsElementBottomConstraint.activate()
                }
                
                self.headerView.radarStatus = detectionStatus.status
            }
            .store(in: &tasks)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.headerView.render()
            }
            .store(in: &tasks)
    }
    
    private func createUI() {
        view.backgroundColor = UIColor.Secondary.blueBackdrop
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        view.addSubview(scrollView)
                
        scrollView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaInsets)
            make.left.right.equalTo(view)
        }
                
        let wrapper = UIView()
        scrollView.addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide.snp.edges)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }
                       
        // Setup header view
        self.headerView = StatusHeaderView()
        wrapper.addSubview(headerView)
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(wrapper)
            make.left.right.equalToSuperview()
        }
        
        headerView.openSettingsHandler = { [unowned self] type in
            let viewController = OpenSettingsViewController.create(type: type) { [unowned self] in
                self.dismiss(animated: true)
            }
            
            self.present(viewController, animated: true)
        }
        
        // Setup notification and helper components
        self.exposuresElement = ExposuresElement() { [unowned self] in
            self.openExposuresViewController()
        } manualCheckAction: { [unowned self] in
            self.runManualDetection()
        }
        
        wrapper.addSubview(self.exposuresElement)

        self.exposuresElement.snp.makeConstraints { make in
            exposuresElementTopConstraint = make.top.equalTo(headerView.snp.bottom).offset(20).constraint
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
                
        self.symptomsElement = SymptomsElement { [unowned self] in
            self.openSymptomsViewController()
        }

        wrapper.addSubview(symptomsElement)
        symptomsElement.snp.makeConstraints { make in
            symptomsElementTopConstraint = make.top.equalTo(exposuresElement.snp.bottom).offset(20).constraint
            make.top.equalTo(headerView.snp.bottom).offset(20).priority(.medium)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        let footer = [
            FooterItem(title: text(key: .ProtectionButtonTitle)) { [unowned self] in
                self.openLink(url: Text.ProtectionButtonURL.toURL()!)
            },

            FooterItem(title: text(key: .SituationButtonTitle)) { [unowned self] in
                self.openLink(url: Text.SituationButtonURL.toURL()!)
            },

            FooterItem(title: text(key: .AppGuideButton)) { [unowned self] in
                showGuide()
            },
        ].build()
        
        wrapper.addSubview(footer)
        footer.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(20).priority(.low)
            exposuresElementBottomConstraint = make.top.equalTo(exposuresElement.snp.bottom).offset(20).priority(.medium).constraint
            symptomsElementBottomConstraint = make.top.equalTo(symptomsElement.snp.bottom).offset(20).priority(.high).constraint
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        let logo = UIImageView(image: UIImage(named: "THL-logo"))
        logo.contentMode = .scaleAspectFit
        wrapper.addSubview(logo)
        logo.snp.makeConstraints { make in
            make.top.equalTo(footer.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(103)
        }

        let logoTapper = UITapGestureRecognizer(target: self, action: #selector(logoImageTapped))
        logo.isUserInteractionEnabled = true
        logo.addGestureRecognizer(logoTapper)
        logo.isAccessibilityElement = true
        logo.accessibilityLabel = Translation.HomeLogoLinkLabel.localized
        logo.accessibilityTraits = .link
        
        #if !PRODUCTION
        let debugButton = UIButton(type: .custom)
        debugButton.setTitle(Translation.ButtonTestUI.localized, for: .normal)
        debugButton.setTitleColor(UIColor.Greyscale.white, for: .normal)
        debugButton.titleLabel?.font = UIFont.labelPrimary
        debugButton.backgroundColor = UIColor.Primary.blue
        debugButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        debugButton.layer.cornerRadius = 6.0
        debugButton.clipsToBounds = true
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        wrapper.addSubview(debugButton)
        
        let bottomGuide = debugButton

        debugButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logo.snp.bottom).offset(30)
        }
        #else
        let bottomGuide = infoButton
        #endif
        
        wrapper.snp.makeConstraints { make in
            make.bottom.equalTo(bottomGuide.snp.bottom).offset(20)
        }
    }
    
    private func openExposuresViewController() {
        openSubview(viewController: ExposuresViewController())
    }
    
    private func openSymptomsViewController() {
        openSubview(viewController: SymptomsViewController())
    }
    
    private func openSubview(viewController: UIViewController) {
        viewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func runManualDetection() {
        BackgroundTaskForNotifications.shared.run()
            .receive(on: RunLoop.main)
            .sink { [weak self] success in
                if !success {
                    self?.showAlert(title: Translation.ManualCheckErrorTitle.localized,
                                    message: Translation.ManualCheckErrorMessage.localized,
                                    buttonText: Translation.ManualCheckErrorButton.localized)
                }
            }
            .store(in: &tasks)
    }
    
    @objc private func debugButtonTapped() {
        let testVC = TestViewController()
        self.present(testVC, animated: true, completion: nil)
    }

    @objc private func logoImageTapped() {
        self.openLink(url: URL(string: Translation.HomeLogoLinkURL.localized)!)
    }
    
    @objc private func willEnterForeground() {
        self.headerView?.render()
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView?.adjustSize(by: scrollView.contentOffset.y, topInset: view.safeAreaInsets.top)
    }
}

#if DEBUG

import SwiftUI

struct MainViewController_Preview: PreviewProvider {
    static var previews: some View = Group {
        createPreview(for: MainViewController(env: .preview {
            .init(exposureStatus: .init(.unexposed))
        }))

        createPreview(for: MainViewController(env: .preview {
            .init(exposureStatus: .init(.exposed(notificationCount: 3)))
        }))
    }
}

#endif

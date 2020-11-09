import Combine
import SnapKit
import UIKit

class MainViewController: UIViewController {
    enum Text : String, Localizable {
        case ProtectionButtonTitle
        case ProtectionButtonURL
        case SituationButtonTitle
        case SituationButtonURL
    }
    
    private var headerView: StatusHeaderView!
    private var notifications: ExposuresElement!
    private var detectionTask: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide navigation bar from view as we have no need for it in main view
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        headerView.render()
    }
    
    private func initUI() {
        self.view.removeAllSubviews()
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
        headerView = StatusHeaderView()
        wrapper.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(wrapper)
            make.left.right.equalToSuperview()
        }
        
        headerView.openSettingsHandler = { [unowned self] type in
            let viewController = OpenSettingsViewController.create(type: type) { self.dismiss(animated: true) }
            self.present(viewController, animated: true)
        }
        
        // Setup notification and helper components
        self.notifications = ExposuresElement() { [unowned self] in
            self.openExposuresViewController()
        } manualCheckAction: {
            self.detectionTask = Environment.default.exposureRepository.runManualCheck().sink { [weak self] success in
                if !success {
                    self?.showAlert(title: Translation.ManualCheckErrorTitle.localized,
                                    message: Translation.ManualCheckErrorMessage.localized,
                                    buttonText: Translation.ManualCheckErrorButton.localized)
                }
            }
        }
        
        wrapper.addSubview(notifications)
        notifications.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        let helper = SymptomsElement(tapped: { [unowned self] in self.openSymptomsViewController() })
        wrapper.addSubview(helper)
        helper.snp.makeConstraints { make in
            make.top.equalTo(notifications.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        // Create wrapper and setup narrow buttons
        let row = UIView()
        wrapper.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.equalTo(helper.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        let howToProtect = NarrowRowElement(image: UIImage(named: "shield-icon")!,
                                            title: Text.ProtectionButtonTitle.localized) { [unowned self] in
            self.openLink(url: Text.ProtectionButtonURL.toURL()!)
        }
        
        row.addSubview(howToProtect)
        howToProtect.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(row.snp.centerX).offset(-10)
        }
        
        let statistics = NarrowRowElement(image: UIImage(named: "finland-map")!,
                                          title: Text.SituationButtonTitle.localized) { [unowned self] in
            self.openLink(url: Text.SituationButtonURL.toURL()!)
        }
        
        row.addSubview(statistics)
        statistics.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(row.snp.centerX).offset(10)
        }
        
        let logo = UIImageView(image: UIImage(named: "THL-logo"))
        logo.contentMode = .scaleAspectFit
        wrapper.addSubview(logo)
        logo.snp.makeConstraints { make in
            make.top.equalTo(row.snp.bottom).offset(28)
            make.left.equalToSuperview().offset(21)
            make.width.equalTo(103)
        }

        let logoTapper = UITapGestureRecognizer(target: self, action: #selector(logoImageTapped))
        logo.isUserInteractionEnabled = true
        logo.addGestureRecognizer(logoTapper)
        logo.isAccessibilityElement = true
        logo.accessibilityLabel = Translation.HomeLogoLinkLabel.localized
        logo.accessibilityTraits = .link

        let infoButton = UIButton(type: .custom)
        infoButton.setTitle(Translation.LinkAppInfo.localized, for: .normal)
        infoButton.setTitleColor(UIColor.Primary.blue, for: .normal)
        infoButton.titleLabel?.font = UIFont.labelSecondary
        infoButton.titleLabel?.textAlignment = .right
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        
        wrapper.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(logo)
            make.left.greaterThanOrEqualTo(logo.snp.right).offset(20)
        }

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
            make.top.equalTo(infoButton.snp.bottom).offset(30)
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
    
    @objc private func debugButtonTapped() {
        let testVC = TestViewController()
        self.present(testVC, animated: true, completion: nil)
    }

    @objc private func infoButtonTapped() {
        showGuide()
    }
    
    @objc private func logoImageTapped() {
        self.openLink(url: URL(string: Translation.HomeLogoLinkURL.localized)!)
    }
    
    @objc private func willEnterForeground() {
        headerView.render()
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        headerView.adjustSize(by: scrollView.contentOffset.y, topInset: view.safeAreaInsets.top)
    }
}

#if DEBUG

import SwiftUI

struct MainViewController_Preview: PreviewProvider {
    static var previews: some View = createPreview(for: MainViewController())
}

#endif

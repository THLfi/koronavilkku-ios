import Foundation
import UIKit
import SnapKit
import Combine

class ExposuresViewController: UIViewController {
    
    enum Text : String, Localizable {
        case TitleHasExposures
    }

    let exposuresViewWrapper = ExposuresViewWrapper()
    var updateTasks = Set<AnyCancellable>()
    var hasExposures: Bool = false
    var detectionStatus: DetectionStatus?
    
    private let button = UIButton()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            hasExposures ? .lightContent : .darkContent
        }
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
        LocalStore.shared.$exposures.$wrappedValue
            .map { $0.count > 0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] hasExposures in
                guard let self = self else {
                    return
                }
                
                if self.hasExposures != hasExposures {
                    self.hasExposures = hasExposures
                    self.updateNavigationBar()
                    self.exposuresViewWrapper.render(hasExposures: self.hasExposures,
                                                     detectionStatus: self.detectionStatus)
                }
            }
            .store(in: &updateTasks)
        
        Environment.default.exposureRepository.detectionStatus
            .receive(on: RunLoop.main)
            .sink { detectionStatus in
                self.exposuresViewWrapper.render(hasExposures: self.hasExposures,
                                                 detectionStatus: detectionStatus)
            }
            .store(in: &updateTasks)
    }
    
    private func updateNavigationBar() {
        guard let navController = navigationController else {
            return
        }
        
        let appearance = navController.navigationBar.standardAppearance.copy()
        navController.navigationBar.prefersLargeTitles = false

        if hasExposures {
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
        Environment.default.exposureRepository.runManualCheck()
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
}


#if DEBUG
import SwiftUI

struct ExposuresViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: ExposuresViewController())
}
#endif

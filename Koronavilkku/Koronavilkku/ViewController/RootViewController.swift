import Foundation
import UIKit

enum RootTab: Int {
    case home = 0
    case reportInfection = 1
    case settings = 2
}

class RootViewController : UITabBarController {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(initialTab selectedTab: RootTab? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        BackgroundTaskManager.shared.scheduleTasks()
        
        // In case a considerable amount of time (batch id changes) elapses before
        // the background task is run the first time, fetch the current batch identifier separately.
        Environment.default.batchRepository.ensureCurrentBatchIdDefined()
        
        viewControllers = [
            createTab(for: MainViewController()) {
                UITabBarItem(
                    title: Translation.TabHome.localized(),
                    image: UIImage.init(named: "home"),
                    selectedImage: UIImage.init(named: "home--active")
                )
            },
            
            // HOX: If you change, add or remove view controllers in this list
            // be sure to update index of ReportInfectionVC in the openReportInfectionScreenWithCode(String?) function
            createTab(for: ReportInfectionViewController()) {
                UITabBarItem(
                    title: Translation.TabReportInfection.localized(),
                    image: UIImage.init(named: "share"),
                    selectedImage: nil
                )
            },
            
            createTab(for: SettingsViewController()) {
                UITabBarItem(
                    title: Translation.TabSettings.localized(),
                    image: UIImage.init(named: "settings"),
                    selectedImage: UIImage.init(named: "settings--active")
                )
            },
        ]
        
        tabBar.unselectedItemTintColor = UIColor.Greyscale.mediumGrey
        tabBar.tintColor = UIColor.Primary.blue
        
        if let selectedTab = selectedTab {
            selectTab(selectedTab)
        }
        
        LocalStore.shared.$language.addObserver(using: {
            self.reloadTabs()
        })
    }
    
    private func createTab(for viewController: UIViewController, createBarItem: () -> UITabBarItem) -> UIViewController {
        let navController = CustomNavigationController(rootViewController: viewController)
        navController.setDefaultStyle()
        
        let titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.tabTitle,
        ]
        
        let barItem = createBarItem()
        barItem.setTitleTextAttributes(titleTextAttributes, for: .normal)
        barItem.imageInsets = UIEdgeInsets(top: 2, left: 0, bottom: -2, right: 0)
        barItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        navController.tabBarItem = barItem
        
        return navController
    }
    
    func openReportInfectionScreenWithCode(code: String) {
        // if we're already in the publish tokens step, just prefill the code
        if
            let navController = presentedViewController as? UINavigationController,
            let publishTokensVC = navController.topViewController as? PublishTokensViewController?
        {
            publishTokensVC?.setCode(code)
            return
        }
        
        // existing modals would prevent the further actions
        presentedViewController?.dismiss(animated: false)

        // navigate to the correct view
        selectTab(.reportInfection)
        guard let navController = tabViewController(.reportInfection) else { return }
        guard let reportInfectionVC = navController.topViewController as? ReportInfectionViewController else { return }
        
        reportInfectionVC.pushToPublishTokensVC(with: code)
    }
    
    func selectTab(_ tab: RootTab) {
        selectedIndex = tab.rawValue
    }
    
    private func tabViewController(_ tab: RootTab) -> CustomNavigationController? {
        return viewControllers?[tab.rawValue] as? CustomNavigationController
    }
    
    private func reloadTabs() {
        let tabs: [RootTab] = [.home, .reportInfection, .settings]
        tabs.forEach { tab in
            guard let tabViewController = self.tabViewController(tab) else {
                return
            }
            
            let title: String
            switch tab {
            case .home:
                tabViewController.viewControllers = [MainViewController()]
                title = Translation.TabHome.localized()
            case .reportInfection:
                tabViewController.viewControllers = [ReportInfectionViewController()]
                title = Translation.TabReportInfection.localized()
            case .settings:
                title = Translation.TabSettings.localized()
            }
            
            tabViewController.tabBarItem.title = title
        }
    }
}

extension UIApplication {
    func selectRootTab(_ tab: RootTab) {
        guard let window = UIApplication.shared.windows.first else { return }
        (window.rootViewController as? RootViewController)?.selectTab(tab)
    }
}

/**
 Extending this in UINavigationController won't work reliably on iOS13,
 but does when properly subclassed. Go figure!
 */
class CustomNavigationController : UINavigationController {
    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}

extension UINavigationController {
    func setDefaultStyle() {
        navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        view.backgroundColor = UIColor.Secondary.blueBackdrop
        navigationBar.tintColor = UIColor.Greyscale.black
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.Secondary.blueBackdrop
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .font: UIFont.heading1,
            .foregroundColor: UIColor.Greyscale.black
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.labelPrimary,
            .foregroundColor: UIColor.Greyscale.black
        ]

        appearance.setBackIndicatorImage(
            UIImage.init(named: "arrow-left"),
            transitionMaskImage: UIImage.init(named: "arrow-left")
        )
        
        navigationBar.standardAppearance = appearance
    }
}

#if DEBUG

import SwiftUI

struct RootViewController_Previews: PreviewProvider {
    static var previews: some View = createPreview(for: RootViewController())
}

#endif

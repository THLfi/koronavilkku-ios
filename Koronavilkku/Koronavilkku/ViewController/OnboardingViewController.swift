import Foundation
import UIKit
import SnapKit
import Combine

class OnboardingViewController: UINavigationController, UINavigationControllerDelegate {
    
    private var currentStep = 0
    private var button: RoundedButton? = nil
    private var scrollIndicatorButton: UIButton? = nil
    private var scrollView: UIScrollView?
    private var activationTask: AnyCancellable?
    
    private lazy var steps: [Step] = [
        // Note that the steps and StepId values must be in the same order.
        Step(id: .intro,
             buttonTitle: Translation.ButtonNext.localized,
             showLanguageSelection: true,
             view: StepView(image: UIImage(named: "radar-static")!,
                            header: Translation.OnboardingIntroTitle.localized,
                            content: Translation.OnboardingIntroText.localized,
                            extraContent: [ createGuideLink() ])
        ),
        Step(id: .concept,
             buttonTitle: Translation.ButtonNext.localized,
             view: StepView(image: UIImage(named: "distributed-tracing")!,
                            header: Translation.OnboardingConceptTitle.localized,
                            content: Translation.OnboardingConceptText.localized,
                            extraContent: [ createGuideLink() ])
        ),
        Step(id: .acceptTerms,
             showScrollIndicator: true,
             view: StepView(image: UIImage(named: "privacy")!,
                            header: Translation.OnboardingYourPrivacyIsProtected.localized,
                            content: Translation.OnboardingHowYourPrivacyIsProtected.localized,
                            extraContent: [
                                TextParagraphView(title: Translation.OnboardingPrivacyTitle.localized,
                                                  content: Translation.OnboardingPrivacyText.localized,
                                                  image: "user"),
                                TextParagraphView(title: Translation.OnboardingUsageTitle.localized,
                                                  content: Translation.OnboardingUsageText.localized,
                                                  image: "database"),
                                TextParagraphView(title: Translation.OnboardingVoluntaryTitle.localized,
                                                  content: Translation.OnboardingVoluntaryText.localized,
                                                  image: "feather",
                                                  divider: false),
                                AcceptableTermsView(label: Translation.OnboardingAcceptTerms.localized,
                                                    externalLinkCaption: Translation.OnboardingReadTerms.localized,
                                                    externalLinkUrl: SettingsViewController.Text.TermsLinkURL.toURL()),
                                AcceptableTermsView(label: Translation.OnbardingVoluntaryUse.localized),
                                RoundedButton(title: Translation.ButtonStartUsing.localized, action: { [weak self] in
                                    // Since step reference isn't available performButtonAction() cannot be called -> call requestApiPermission() directly.
                                    self?.requestApiPermission()
                                })
                            ])
        ),
        Step(id: .enableApiInstructions,
             viewController: OpenSettingsViewController.create(
                type: .exposureNotifications,
                userDismissable: false,
                dismisser: { [weak self] in self?.onEnableDismissed() }
             )
        ),
        Step(id: .enableBluetooth,
             viewController: OpenSettingsViewController.create(
                type: .bluetooth,
                userDismissable: false,
                dismisser: { [weak self] in self?.onEnableDismissed() }
             )
        ),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setDefaultStyle()
        self.setNavigationBarHidden(true, animated: false)
        let window = UIApplication.shared.windows.first
        let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame
        if let statusBarFrame = statusBarFrame {
            let blurEffect = UIBlurEffect(style: .regular)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = statusBarFrame
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(blurEffectView)
        }
        
        self.delegate = self
        self.view.backgroundColor = UIColor.Greyscale.white
        self.handleStartStep()
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ChangeLanguageViewController {
            self.largeTitleFont = .heading2
            self.setNavigationBarHidden(false, animated: true)
        } else if !navigationBar.isHidden {
            self.largeTitleFont = .heading1
            self.setNavigationBarHidden(true, animated: true)
        }
    }
    
    private func performButtonAction(step: Step) {
        
        if let requestPermission = step.requestPermission {
            requestPermission()
        } else {
            stepDone()
        }
    }
    
    private func requestApiPermission(showOverlay: Bool = false) {
        var overlay: LabeledOverlay? = nil
        
        if showOverlay {
            overlay = self.showLabeledOverlay(with: Translation.HeaderContinueByAcceptingExposureLogging.localized)
        }
        
        let exposureManager = ExposureManagerProvider.shared.manager
        
        // TODO: Refactor this to use ExposureRepository tryEnable
        exposureManager.setExposureNotificationEnabled(true, completionHandler: { [weak self] error in
            guard let weakSelf = self else { return }
            
            if let overlay = overlay {
                weakSelf.hideshowLabeledOverlay(overlay)
            }
            
            let status = exposureManager.exposureNotificationStatus
            Log.d("Exposure manager status after enable-call: \(status.rawValue)")
            // In the bluetoothOff case complete onboarding. In the main view the user will be shown that Bluetooth
            // needs to be enabled.
            
            if status == .bluetoothOff {
                weakSelf.step(into: .enableBluetooth)
                
            } else if let error = error {
                
                Log.e("Failed to enable: \(error.localizedDescription)")

                // User didn't grant permission to use EN. Next step gives instructions on how to
                // enable EN via settings. After user has done that and returns to the app, check
                // whether the app is now authorized to use EN and if it is, then proceed to the next step.
                weakSelf.step(into: .enableApiInstructions)
                
                // Save the current step because the app seems to get killed after changing the EN setting.
                // This way the user doesn't have to start onboarding from the beginning.
                LocalStore.shared.onboardingResumeStep = StepId.enableApiInstructions.rawValue
                
            } else {
                LocalStore.shared.uiStatus = .on
                weakSelf.stepDone()
            }
        })
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            DispatchQueue.main.async {
                self.stepDone()
            }
        }
    }
    
    private func stepDone() {
        currentStep += 1
        
        if let id = StepId(rawValue: currentStep) {
            step(into: id)
        } else {
            onCompleted()
        }
    }
    
    private func onCompleted() {
        LocalStore.shared.isOnboarded = true
        // Return to main view after a delay
        let onBoardingDone = OnboardingDoneView {
            
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = RootViewController()
                window.makeKeyAndVisible()
                UIView.defaultTransition(with: window, animations: nil)
            }
        }
        
        UIView.defaultTransition(with: self.view) {
            self.view.removeAllSubviews()
            self.view.addSubview(onBoardingDone)
            onBoardingDone.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func onEnableDismissed() {
        let exposureManager = ExposureManagerProvider.shared.manager
        
        if exposureManager.exposureNotificationStatus == .disabled {
            requestApiPermission(showOverlay: false)
        } else {
            stepDone()
        }
    }
    
    private func scrollDown() {
        guard let scrollView = self.scrollView else { return }
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
        hideScrollIndicator()
    }
    
    private func step(into step: StepId) {
        Log.d("Step into \(step)")
        
        if let oldScrollView = scrollView {
            oldScrollView.delegate = nil
        }
        
        let index = step.rawValue
        currentStep = index
        let step = steps[index]
        let viewController = step.viewController ?? initStepViewController(from: step, stepView: step.view!)

        // skip steps where the prerequisite is already met, eg.
        // EN API is activated, BT is on…
        if self.requiresPresenting(viewController: viewController) {
            self.pushViewController(viewController, animated: true)
            self.updateButtonState()
        }
    }

    private func requiresPresenting(viewController: UIViewController) -> Bool {
        guard
            let osvc = viewController as? OpenSettingsViewController,
            osvc.dismissCheck(LocalStore.shared.uiStatus)
        else {
            return true
        }
        
        // "dismisses" by moving to the next step
        osvc.dismisser()
        return false
    }
    
    private func initStepViewController(from step: Step, stepView: StepView) -> UIViewController {
        self.scrollView = UIScrollView()
        self.scrollView?.backgroundColor = .white
        self.scrollView?.alwaysBounceVertical = true
        let viewController = UIViewController()
        viewController.view.addSubview(scrollView!)
        scrollView!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView!.addSubview(stepView)
        stepView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.left.right.equalTo(viewController.view)
        }
        
        if step.showLanguageSelection {
            let languageButton = createLanguageSelectionButton()
            scrollView?.addSubview(languageButton)
            
            languageButton.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.right.equalToSuperview().inset(20)
            }
        }
        
        let fade = FadeBlock()
        viewController.view.addSubview(fade)
        
        let buttonMargin = UIEdgeInsets(top: 10, left: 40, bottom: 60, right: 40)
        let buttonHeight = RoundedButton.height
        self.button = nil
        
        if let buttonTitle = step.buttonTitle {
            let button = RoundedButton(title: buttonTitle) { [unowned self] in
                self.performButtonAction(step: step)
            }
            viewController.view.addSubview(button)
            button.snp.makeConstraints { make in
                make.bottom.left.right.equalToSuperview().inset(buttonMargin)
            }
            self.button = button
            
        } else if step.showScrollIndicator {
            let button = RoundedButton(title: "\u{2193}", action: self.scrollDown)
            button.accessibilityHint = Translation.ButtonScrollDown.localized
            viewController.view.addSubview(button)
            button.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 50, height: 50))
                make.bottom.equalToSuperview().inset(buttonMargin)
                make.centerX.equalToSuperview()
            }
            self.scrollIndicatorButton = button
            scrollView!.delegate = self
        }
        
        fade.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(buttonHeight + buttonMargin.top + buttonMargin.bottom)
        }
        
        stepView.extraContent?
            .filter({ $0 is AcceptableView })
            .map({ $0 as! AcceptableView })
            .forEach({
                var view = $0
                view.delegate = self
            })
        
        if let fixedButton = stepView.extraContent?.last as? RoundedButton, self.button == nil {
            self.button = fixedButton
        }
        
        return viewController
    }
    
    private func updateButtonState() {
        guard let button = self.button else { return }
        
        // Check if there are any extra views that require acceptance before continuing
        guard let acceptanceProviders = steps[currentStep].view?.extraContent?.filter({ $0 is AcceptableView }) else {
            // Nope... let the button remain enabled
            button.setEnabled(true)
            return
        }
        
        // Check views though and enable button if all acceptance views are in accepted state
        let enabled = acceptanceProviders
            .map({ $0 as! AcceptableView })
            .allSatisfy({ $0.accepted }) ? true : false
        button.setEnabled(enabled)
    }
    
    private func createGuideLink() -> InternalLinkLabel {
        return InternalLinkLabel(label: Translation.HowItWorksButton.localized,
                                 font: UIFont.labelSecondary,
                                 color: UIColor.Primary.blue,
                                 linkTapped: { [unowned self] in self.showGuide() },
                                 underline: false)
    }
    
    private func createLanguageSelectionButton() -> UIButton {
        let button = UIButton()
        
        button.addTarget(self, action: #selector(languageSelectionTapped), for: .touchUpInside)
        button.setTitle("Language", for: .normal)
        button.backgroundColor = UIColor.Secondary.blueBackdrop
        button.setTitleColor(UIColor.Primary.blue, for: .normal)
        button.titleLabel?.font = .bodySmall
        button.layer.cornerRadius = 6
        button.setImage(UIImage(named: "globe")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 10)
        button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.Primary.blue

        return button
    }
    
    private func hideScrollIndicator() {
        guard let indicator = scrollIndicatorButton else { return }
        self.scrollIndicatorButton = nil
        indicator.removeFromSuperview()
    }
    
    private func handleStartStep() {
        let resumeStepIndex = LocalStore.shared.onboardingResumeStep
        LocalStore.shared.onboardingResumeStep = nil
        
        if let resumeStepIndex = resumeStepIndex, let resumeStepId = StepId(rawValue: resumeStepIndex) {
            Log.d("Resume at \(resumeStepId)")
            
            // Make sure ExposureManager is active before proceeding as the status might be needed during step(into:).
            activationTask = ExposureManagerProvider.shared.activated.sink { [weak self] activated in
                
                if activated {
                    self?.step(into: resumeStepId)
                } else {
                    self?.step(into: .intro)
                }
            }
            
        } else {
            step(into: .intro)
        }
    }

    @objc func languageSelectionTapped() {
        pushViewController(ChangeLanguageViewController(), animated: true)
    }
}

struct Step {
    let id: StepId
    let buttonTitle: String?
    let showScrollIndicator: Bool
    let showLanguageSelection: Bool
    let view: StepView?
    let viewController: UIViewController?
    let requestPermission: (() -> ())?
    
    init(
        id: StepId,
        buttonTitle: String? = nil, showScrollIndicator: Bool = false, showLanguageSelection: Bool = false, view: StepView? = nil, viewController: UIViewController? = nil, requestPermission: (() -> ())? = nil)
    {
        self.id = id
        self.buttonTitle = buttonTitle
        self.showScrollIndicator = showScrollIndicator
        self.showLanguageSelection = showLanguageSelection
        self.view = view
        self.viewController = viewController
        self.requestPermission = requestPermission
    }
}

enum StepId: Int {
    case intro = 0
    case concept
    case acceptTerms
    case enableApiInstructions
    case enableBluetooth
    
    var description: String { return "StepId(\(String(describing: self))" }
}

extension OnboardingViewController: AcceptDelegate {
    func statusChanged() {
        self.updateButtonState()
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        guard contentHeight > 0 else { return }
        let hideOffset: CGFloat = 100
        
        if scrollView.contentOffset.y > contentHeight - view.frame.height - hideOffset {
            hideScrollIndicator()
        }
    }
}

extension UIScrollView {
    func updateContentView() {
        contentSize.height = subviews.sorted(by: { $0.frame.maxY < $1.frame.maxY }).last?.frame.maxY ?? contentSize.height
    }
}

class FadeBlock: UIView {
    
    private let gradientLayer: CAGradientLayer
    
    init() {
        self.gradientLayer = CAGradientLayer()
        
        super.init(frame: .zero)
        
        let color = UIColor.white
        gradientLayer.colors = [color.withAlphaComponent(0.0).cgColor, color.cgColor]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        layer.addSublayer(gradientLayer)
        
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

#if DEBUG
import SwiftUI

struct OnboardingViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: OnboardingViewController())
}
#endif

import Combine
import SnapKit
import UIKit

class PublishTokensViewController: BaseReportInfectionViewController {
    enum Text : String, Localizable {
        case Title
        case ButtonSubmit
        case AdditionalText
        case ErrorWrongPublishToken
        case ErrorNetwork
    }
    
    private let scrollView = UIScrollView()
    
    private lazy var button = RoundedButton(title: Text.ButtonSubmit.localized) { [unowned self] in
        self.sendPressed()
    }
    
    private lazy var tokenCodeField = TokenCodeField() { [unowned self] in
        self.updateButtonEnabled()
    }
    
    private var errorView: UIView!
    private var errorLabel: UILabel!
    private var progressIndicator = UIActivityIndicatorView(style: .large)
    private let wrapper = UIView()
    private lazy var infoLabel = createInfoLabel()
    
    var failure: NSError? = nil {
        didSet {
            progressIndicator.stopAnimating()
            progressIndicator.isHidden = true
            
            button.isEnabled = true
            button.isUserInteractionEnabled = true
            
            updateErrorView(with: failure)
        }
    }
    
    var tasks = [AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addKeyboardDisposer()
        
        title = Text.Title.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Translation.ButtonCancel.localized, style: .plain, target: self, action: #selector(close))
        
        bindKeyboardEvents()
        initUI()
        
        flowController.$viewModel.sink { [weak self] viewModel in
            guard let self = self, let code = viewModel.publishToken else { return }

            self.tokenCodeField.text = code
            self.updateButtonEnabled()
        }.store(in: &tasks)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if tokenCodeField.text?.isEmpty == true {
            // No code was provided (not opened via link) -> show keyboard.
            tokenCodeField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    func bindKeyboardEvents() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification).sink { [weak self] notification in
            guard let keyboardSize = notification.keyboardSize else {
               return
            }

            self?.infoLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(keyboardSize.height + 20)
            }
        }.store(in: &tasks)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification).sink { [weak self] notification in
            guard let self = self, let keyboardSize = notification.keyboardSize else {
               return
            }
            
            // if possible, scroll all the way to bottom
            let rectHeight = self.wrapper.frame.height - self.tokenCodeField.frame.minY + keyboardSize.height

            // but prevent the tokenCodeField from being scrolled over
            let rectMaxHeight = self.view.frame.height - self.view.safeAreaInsets.top - 8

            let rect = CGRect(x: self.tokenCodeField.frame.maxX,
                              y: self.tokenCodeField.frame.minY,
                              width: self.tokenCodeField.frame.width,
                              height: rectHeight > rectMaxHeight ? rectMaxHeight : rectHeight)

            self.scrollView.scrollRectToVisible(rect, animated: true)
        }.store(in: &tasks)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification).sink { [weak self] notification in
            self?.infoLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(20)
            }
        }.store(in: &tasks)
    }
    
    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func initUI() {
        view.addSubview(scrollView)
        
        scrollView.isUserInteractionEnabled = true
        scrollView.alwaysBounceVertical = true
        
        scrollView.backgroundColor = UIColor.Secondary.blueBackdrop
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaInsets)
            make.left.right.equalTo(view)
            make.bottom.equalTo(view.safeAreaInsets)
        }
        
        scrollView.addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        wrapper.isUserInteractionEnabled = true

        errorView = createErrorView()
        errorView.isHidden = true
        wrapper.addSubview(errorView)
        errorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        tokenCodeField.accessibilityLabel = Text.Title.localized
        updateButtonEnabled()

        wrapper.addSubview(tokenCodeField)
        tokenCodeField.snp.makeConstraints { make in
            make.top.equalTo(errorView.snp.bottom).offset(20)
            make.left.right.equalTo(view).inset(20)
            make.height.equalTo(63)
        }

        wrapper.addSubview(progressIndicator)
        progressIndicator.isHidden = true
        progressIndicator.snp.makeConstraints { make in
            make.centerY.equalTo(errorView.snp.centerY)
            make.left.right.equalTo(view).inset(20)
            make.height.equalTo(40)
        }

        wrapper.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(tokenCodeField.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(20)
        }
        
        wrapper.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    private func createInfoLabel() -> UILabel {
        let label = UILabel(label: Text.AdditionalText.localized,
                       font: UIFont.bodySmall,
                       color: UIColor.Greyscale.black)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
    
    private func createErrorView() -> UIView {
        let wrapper = UIView()
        
        let image = UIImageView(image: UIImage(named: "alert-octagon")!.withTintColor(UIColor.Primary.red))
        image.contentMode = .scaleAspectFit
        wrapper.addSubview(image)
        image.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        errorLabel = UILabel(label: Text.ErrorWrongPublishToken.localized,
                       font: UIFont.heading5,
                       color: UIColor.Primary.red)
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
        wrapper.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(14)
            make.top.equalTo(image)
            make.right.bottom.equalToSuperview()
        }
        
        return wrapper
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func sendPressed() {
        errorView.isHidden = true
        progressIndicator.startAnimating()
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        view.endEditing(true)
        
        flowController.submit(publishToken: tokenCodeField.text)
    }
    
    private func updateErrorView(with failure: NSError?) {
        
        if let failure = failure {
            errorView.isHidden = false
            
            if failure.equals(.notAuthorized) {
                errorView.isHidden = true
            } else if failure.domain == NSURLErrorDomain {
                errorLabel.text = Text.ErrorNetwork.localized
            } else if failure.domain == KVRestErrorDomain {
                errorLabel.text = Text.ErrorWrongPublishToken.localized
            } else {
                errorLabel.text = "\(Text.ErrorWrongPublishToken.localized) (\(failure.code))"
            }
            
            if !errorView.isHidden {
                UIAccessibility.post(notification: .screenChanged, argument: errorLabel)
            }
            
        } else {
            errorView.isHidden = true
        }

        // Don't show the error text if user didn't grant permission to use keys (as it would be misleading).
        errorView.isHidden = failure == nil || failure!.equals(.notAuthorized)
    }
    
    private func updateButtonEnabled() {
        let invalid = tokenCodeField.text?.isEmpty == true
        button.setEnabled(!invalid)
    }
}

extension Notification {
    var keyboardSize: CGRect? {
        (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }
}

#if DEBUG
import SwiftUI

struct PublishTokensViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: UINavigationController(rootViewController: PublishTokensViewController()))
}
#endif

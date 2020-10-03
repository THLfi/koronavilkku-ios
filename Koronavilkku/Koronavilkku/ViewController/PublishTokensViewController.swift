import Foundation
import UIKit
import SnapKit
import Combine
import ExposureNotification

class PublishTokensViewController: UIViewController {
    enum Text : String, Localizable {
        case Title
        case ButtonSubmit
        case AdditionalText
        case ErrorWrongPublishToken
        case ErrorNetwork
        case FinishedTitle
        case FinishedText
        case FinishedButton
    }
    
    private let scrollView = UIScrollView()
    private lazy var button = RoundedButton(title: Text.ButtonSubmit.localized,
                                            action: { [weak self] in self?.sendPressed() })
    private let tokenCodeField = UITextField()
    private var errorView: UIView!
    private var errorLabel: UILabel!
    private var progressIndicator = UIActivityIndicatorView(style: .large)
    private let wrapper = UIView()
    private lazy var infoLabel = createInfoLabel()
    
    private var failure: NSError? = nil {
        didSet {
            progressIndicator.stopAnimating()
            progressIndicator.isHidden = true
            
            button.isEnabled = true
            button.isUserInteractionEnabled = true
            
            updateErrorView(with: failure)
        }
    }
    
    let exposureRepository = Environment.default.exposureRepository
    var tasks = [AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addKeyboardDisposer()
        
        navigationItem.title = Text.Title.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Translation.ButtonCancel.localized, style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem?.accessibilityLabel = Translation.ButtonBack.localized
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        initUI()
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
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           return
        }

        self.infoLabel.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(keyboardSize.height + 20)
        }
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           return
        }
        
        // if possible, scroll all the way to bottom
        let rectHeight = wrapper.frame.height - tokenCodeField.frame.minY + keyboardSize.height

        // but prevent the tokenCodeField from being scrolled over
        let rectMaxHeight = view.frame.height - view.safeAreaInsets.top - 8

        let rect = CGRect(x: tokenCodeField.frame.maxX,
                          y: tokenCodeField.frame.minY,
                          width: tokenCodeField.frame.width,
                          height: rectHeight > rectMaxHeight ? rectMaxHeight : rectHeight)

        self.scrollView.scrollRectToVisible(rect, animated: true)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        self.infoLabel.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(20)
        }
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
                                
        tokenCodeField.backgroundColor = UIColor.Greyscale.white
        tokenCodeField.layer.shadowColor = .dropShadow
        tokenCodeField.layer.shadowOpacity = 0.1
        tokenCodeField.layer.shadowOffset = CGSize(width: 0, height: 4)
        tokenCodeField.layer.shadowRadius = 14
        tokenCodeField.font = UIFont.coronaCode
        tokenCodeField.layer.cornerRadius = 8
        tokenCodeField.textAlignment = .center
        tokenCodeField.keyboardType = .asciiCapableNumberPad
        tokenCodeField.autocorrectionType = .no
        tokenCodeField.delegate = self
        tokenCodeField.accessibilityLabel = Text.Title.localized
        tokenCodeField.addTarget(self, action: #selector(updateButtonEnabled), for: .editingChanged)

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
    
    func setCode(_ code: String) {
        tokenCodeField.text = code
        updateButtonEnabled()
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
    
    @objc func sendPressed() {
        DispatchQueue.main.async {
            self.errorView.isHidden = true
            self.progressIndicator.startAnimating()
            self.button.isEnabled = false
            self.button.isUserInteractionEnabled = false
            self.view.endEditing(true)
        }
        exposureRepository.postExposureKeys(publishToken: tokenCodeField.text ?? nil)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .failure(let error as NSError):
                        Log.e("Failed to post exposure keys: \(error)")
                        self.failure = error

                    case .finished:
                        self.showFinishViewController()
                    }
                },
                receiveValue: {}
            )
            .store(in: &tasks)
    }
    
    func showFinishViewController() {
        let finishViewController = InfoViewController()
        finishViewController.image = UIImage(named: "ok")
        finishViewController.titleText = Text.FinishedTitle.localized
        finishViewController.textLabelText = Text.FinishedText.localized
        finishViewController.buttonTitle = Text.FinishedButton.localized
        finishViewController.buttonPressed = {
            UIApplication.shared.selectRootTab(.home)
            finishViewController.dismiss(animated: true, completion: nil)
        }
        
        self.show(finishViewController, sender: self.parent)
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
    
    @objc private func updateButtonEnabled() {
        let invalid = tokenCodeField.text?.isEmpty == true
        button.setEnabled(!invalid)
    }
}

extension NSError {
    func equals(_ code: ENError.Code) -> Bool {
        return domain == ENErrorDomain && self.code == code.rawValue
    }
}

extension PublishTokensViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let oldLength = textField.text?.count ?? 0
        let replacementLength = string.count
        let rangeLength = range.length
        
        let newLength = oldLength - rangeLength + replacementLength
        
        let returnPressed = string.range(of: "\n") != nil
        
        return newLength <= 12 || returnPressed
    }
}

#if DEBUG
import SwiftUI

struct PublishTokensViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: UINavigationController(rootViewController: PublishTokensViewController()))
}
#endif

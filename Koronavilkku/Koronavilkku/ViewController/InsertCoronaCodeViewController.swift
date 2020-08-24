import Foundation
import UIKit
import SnapKit
import Combine

class PublishTokensViewController: UIViewController {
    
    private let viewWrapper = UIScrollView()
    private lazy var button = RoundedButton(title: Translation.ButtonSend.localized,
                                            action: { [weak self] in self?.sendPressed() })
    private let coronaCodeField = UITextField()
    private let codeFieldWrapper = UIView()
    private var codeFieldOriginY: CGFloat = 0
    private lazy var infoView: UIView = self.createInfoLabel()
    private var helperLabel = UILabel()
    private var progressIndicator = UIActivityIndicatorView(style: .large)
    
    private var failed = false {
        didSet {
            progressIndicator.removeFromSuperview()
            infoView.removeFromSuperview()
            self.button.isEnabled = true
            self.button.isUserInteractionEnabled = true
            self.progressIndicator.stopAnimating()
            
            switch failed {
            case true:
                infoView = createWarningLabel()
            case false:
                infoView = createInfoLabel()
            }
            self.populateInfoViewAndFixConstraints()
        }
    }
    
    var code: String?
    let exposureRepository = Environment.default.exposureRepository
    var tasks = [AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addKeyboardDisposer()
        
//        navigationItem.title = Translation.ReportTitle.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Translation.ButtonCancel.localized, style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(close))
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.largeTitleDisplayMode = .automatic
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func initUI() {
        viewWrapper.isScrollEnabled = true
        viewWrapper.isUserInteractionEnabled = true
        view.addSubview(viewWrapper)
        
        viewWrapper.backgroundColor = UIColor.Secondary.blueBackdrop
        viewWrapper.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        helperLabel.attributedText = [
            BulletListParagraph(content: Translation.BulletListEnsureDevice.localized, lineSpacing: 1),
            BulletListParagraph(content: Translation.BulletListCoronaCodeInsertionIdentityWillNotBeRevealed.localized, lineSpacing: 1)
        ].asMutableAttributedString()
        helperLabel.numberOfLines = 0
        viewWrapper.addSubview(helperLabel)
        
        helperLabel.snp.makeConstraints { make in
            make.top.equalTo(viewWrapper).offset(20)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
        }
        
        // Create wrapper for code field
        codeFieldWrapper.backgroundColor = UIColor.Greyscale.white
        codeFieldWrapper.layer.cornerRadius = 14
        codeFieldWrapper.layer.shadowColor = UIColor.Greyscale.black.cgColor
        codeFieldWrapper.layer.shadowOpacity = 0.2
        codeFieldWrapper.layer.shadowOffset = .zero
        codeFieldWrapper.layer.shadowRadius = 14
        
        viewWrapper.addSubview(codeFieldWrapper)
        codeFieldWrapper.snp.makeConstraints { make in
            make.top.equalTo(helperLabel.snp.bottom).offset(24)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.height.equalTo(127)
        }
       
        let codeFieldTitle = UILabel(label: Translation.HeaderInsertCoronaCode.localized,
                                     font: UIFont.heading4,
                                     color: UIColor.Greyscale.black)
        codeFieldTitle.textAlignment = .center
        
        codeFieldWrapper.addSubview(codeFieldTitle)
        codeFieldTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(10)
        }
    
        coronaCodeField.backgroundColor = UIColor.Greyscale.backdropGrey
        coronaCodeField.font = UIFont.coronaCode
        coronaCodeField.layer.cornerRadius = 8
        coronaCodeField.textAlignment = .center
        coronaCodeField.keyboardType = .asciiCapableNumberPad
        coronaCodeField.delegate = self

        if let _ = self.code {
            coronaCodeField.text = code
            self.code = nil
        }
        
        codeFieldWrapper.addSubview(coronaCodeField)
        coronaCodeField.snp.makeConstraints { make in
            make.top.equalTo(codeFieldTitle.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(68)
        }
        viewWrapper.addSubview(button)
        populateInfoViewAndFixConstraints()
        
    }
    
    private func populateProgressIndicatorAndFixConstraints() {
        infoView.removeFromSuperview()
        
        viewWrapper.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints { make in
            make.top.equalTo(coronaCodeField.snp.bottom).offset(35)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.height.equalTo(40)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(progressIndicator.snp.bottom).offset(20)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
        }
    }
    
    private func populateInfoViewAndFixConstraints() {
        progressIndicator.removeFromSuperview()
        
        viewWrapper.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.top.equalTo(coronaCodeField.snp.bottom).offset(35)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.height.equalTo(40)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(infoView.snp.bottom).offset(20)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
        }
    }
    
    private func createInfoLabel() -> UILabel {
        let label = UILabel(label: Translation.LabelSendInfoToBackend.localized.uppercased(),
                       font: UIFont.heading5,
                       color: UIColor.Greyscale.darkGrey)
        label.textAlignment = .center
        return label
    }
    
    private func createWarningLabel() -> UIView {
        let wrapper = UIView()
        
        let image = UIImageView(image: UIImage(named: "alert-octagon")!.withTintColor(UIColor.Primary.red))
        image.contentMode = .scaleAspectFit
        wrapper.addSubview(image)
        image.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(22)
        }
        
        let label = UILabel(label: Translation.LabelWrongAuthenticationCode.localized,
                       font: UIFont.heading5,
                       color: UIColor.Primary.red)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        wrapper.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(14)
            make.top.equalTo(image)
            make.right.equalToSuperview()
        }
        
        return wrapper
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func sendPressed() {
        DispatchQueue.main.async {
            print("Populate progress indicator")
            self.populateProgressIndicatorAndFixConstraints()
            self.progressIndicator.startAnimating()
            self.button.isEnabled = false
            self.button.isUserInteractionEnabled = false
        }
        exposureRepository.postExposureKeys(publishToken: coronaCodeField.text ?? nil)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .failure(_):
                        self.failed = true
                    case .finished:
                        LocalStore.shared.uiStatus = .locked
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
        finishViewController.titleText = Translation.ThankYouForPublishingTitle.localized
        finishViewController.textLabelText = Translation.ThankYouForPublishingMessage.localized
        finishViewController.buttonTitle = Translation.ThankYouForPublishingButtonTitle.localized
        finishViewController.buttonPressed = { finishViewController.dismiss(animated: true, completion: nil) }
        
        self.show(finishViewController, sender: self.parent)
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

struct InsertCoronaCodeViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for: UINavigationController(rootViewController: PublishTokensViewController()))
}
#endif

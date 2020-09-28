import SnapKit
import UIKit

class ChangeLanguageViewController: UIViewController {
    
    enum Text : String, Localizable {
        case Title
        case Message
        case ButtonTitle
        case UniversalExplanation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Text.Title.localized
        view.backgroundColor = UIColor.Secondary.blueBackdrop
        
        let content = view.addScrollableContentView(
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        
        let message = UILabel(
            label: Text.Message.localized,
            font: .bodyLarge,
            color: UIColor.Greyscale.black)
        
        message.numberOfLines = -1
        content.addSubview(message)
        
        message.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        let button = LinkItemCard(title: Text.ButtonTitle.localized) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        
        content.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.top.equalTo(message.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
        }
        
        let universalText = UILabel(
            label: Text.UniversalExplanation.localized.uppercased(),
            font: .heading5,
            color: UIColor.Greyscale.darkGrey)
        
        universalText.textAlignment = .center
        content.addSubview(universalText)
        
        universalText.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

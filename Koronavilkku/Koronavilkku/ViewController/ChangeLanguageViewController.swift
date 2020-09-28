import SnapKit
import UIKit

class ChangeLanguageViewController: UIViewController {
    
    enum Text : String, Localizable {
        case Title
        case Message
        case ButtonTitle
        case UniversalTitle
        case UniversalMessage
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
        
        let universalTitle = UILabel(
            label: Text.UniversalTitle.localized.uppercased(),
            font: .heading5,
            color: UIColor.Greyscale.darkGrey)
        
        universalTitle.textAlignment = .center
        content.addSubview(universalTitle)
        
        universalTitle.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
        }

        let universalMessage = UILabel(
            label: Text.UniversalMessage.localized,
            font: .bodySmall,
            color: UIColor.Greyscale.darkGrey)
        
        universalMessage.numberOfLines = -1
        universalMessage.textAlignment = .center
        content.addSubview(universalMessage)
        
        universalMessage.snp.makeConstraints { make in
            make.top.equalTo(universalTitle.snp.bottom).offset(6)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

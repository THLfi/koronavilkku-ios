
import Foundation
import UIKit

class InfoViewController: UIViewController {
    
    private let viewWrapper = UIScrollView()
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let textLabel = UILabel()
    
    var image = UIImage(systemName: "circle.fill")
    var titleText = "Placeholder"
    var textLabelText = "Placeholder"
    typealias ButtonPressed = () -> Void
    var buttonPressed: ButtonPressed? = nil
    var buttonTitle = "Placeholder"
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewWrapper.isScrollEnabled = true
        viewWrapper.isUserInteractionEnabled = true
        view.addSubview(viewWrapper)
        
        viewWrapper.backgroundColor = UIColor.Secondary.blueBackdrop
        viewWrapper.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        viewWrapper.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            make.left.equalTo(view).offset(40)
            make.right.equalTo(view).offset(-40)
            make.height.equalToSuperview().dividedBy(4)
        }
        
        titleLabel.text = titleText
        titleLabel.font = .heading1
        titleLabel.numberOfLines = 0
        viewWrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.left.equalTo(view).offset(40)
            make.right.equalTo(view).offset(-40)
        }
        
        textLabel.text = textLabelText
        textLabel.font = UIFont.bodySmall
        textLabel.textColor = UIColor.Greyscale.darkGrey
        textLabel.numberOfLines = 0
        viewWrapper.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(view).offset(40)
            make.right.equalTo(view).offset(-40)
        }
        
        let button = RoundedButton(title: buttonTitle, action: { [unowned self] in self.buttonPressed?() })
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-40)
            make.left.equalTo(view).offset(40)
            make.right.equalTo(view).offset(-40)
            make.height.equalTo(50)
        }
    }
}

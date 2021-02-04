import SnapKit
import UIKit

class CheckDelayedView : CardElement {
    var detectionRunning: Bool = false {
        didSet {
            button.isLoading = detectionRunning
        }
    }
    
    private let button: RoundedButton!
    
    init(buttonAction: @escaping () -> ()) {
        self.button = RoundedButton(title: ExposuresElement.Text.ButtonCheckNow.localized,
                                    backgroundColor: UIColor.Primary.blue,
                                    highlightedBackgroundColor: UIColor.Secondary.buttonHighlightedBackground,
                                    action: buttonAction)
        super.init()
        createUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createUI() {
        let label = UILabel(label: ExposuresElement.Text.BodyExposureCheckDelayed.localized,
                            font: .labelTertiary,
                            color: UIColor.Greyscale.black)
        
        label.numberOfLines = 0
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(20)
        }
        
        addSubview(button)
        
        button.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(30)
        }
    }
}

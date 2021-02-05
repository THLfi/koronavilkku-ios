import SnapKit
import UIKit

class ExposureGuideViewController : UIViewController, LocalizedView {
    enum Text : String, Localizable {
        case Title
    }
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var screenCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUI()
        addScreen(text: .Title, image: UIImage(named: ""))
    }

    private func createUI() {
        let bottom = UIView()
        bottom.backgroundColor = .white
        view.addSubview(bottom)
        
        bottom.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaInsets)
            make.height.equalTo(60)
        }
        
        scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.backgroundColor = UIColor.Secondary.blueBackdrop
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaInsets)
            make.left.right.equalTo(view)
            make.bottom.equalTo(bottom.snp.top)
        }
        
        stackView = UIStackView()
        scrollView.addSubview(stackView)
        stackView.distribution = .equalSpacing
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide.snp.edges).inset(0)
        }
    }
    
    private func addScreen(text: Text, image: UIImage?) {
        screenCount += 1
        
        let view = UIView()
        view.backgroundColor = .red

        stackView.addArrangedSubview(view)

        view.snp.makeConstraints { make in
            make.width.equalTo(scrollView)
            make.height.equalTo(scrollView).priority(.low)
        }
    }
}

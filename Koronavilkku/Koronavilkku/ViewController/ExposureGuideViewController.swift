import SnapKit
import UIKit

class NumberView : UIView {
    init(number: Int) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.Primary.blue

        let label = UILabel(label: "\(number)", font: .heading4, color: UIColor.Greyscale.white)
        label.textAlignment = .center
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(5)
        }
        
        snp.makeConstraints { make in
            make.width.equalTo(snp.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ExposureGuideViewController : UIViewController, LocalizedView, UIScrollViewDelegate, UIPageViewControllerDelegate {
    
    enum Text : String, Localizable {
        case Title
        case ButtonClose
        case ButtonPrevious
        case ButtonNext
        case Step1
        case Step2
        case Step3
        case Step4
        case Step5
    }
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var primaryButton: UIButton!
    private var secondaryButton: UIButton!
    private var pageControl: UIPageControl!
    private var screenCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUI()
        addScreen(title: .Title, body: .Step1, image: UIImage(named: "exposure-guide-1"))
        addScreen(body: .Step2, image: UIImage(named: "exposure-guide-2"))
        addScreen(body: .Step3, image: UIImage(named: "exposure-guide-3"))
        addScreen(body: .Step4, image: UIImage(named: "exposure-guide-4"))
        addScreen(body: .Step5, image: UIImage(named: "exposure-guide-5"))
        pageControl.numberOfPages = screenCount
        pageChanged()
    }

    private func createUI() {
        view.backgroundColor = UIColor.Greyscale.white
        
        let bottom = createBottomBar()
        
        scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.backgroundColor = UIColor.Greyscale.white
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            make.bottom.equalTo(bottom.snp.top)
        }
        
        stackView = UIStackView()
        scrollView.addSubview(stackView)
        stackView.distribution = .equalSpacing
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide.snp.edges).inset(0)
        }

        let closeButton = UIButton(type: .close)
        view.addSubview(closeButton)

        closeButton.addTarget(self,
                              action: #selector(self.close),
                              for: .touchUpInside)
        
        closeButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(20)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }

    }
    
    private func addScreen(title: Text? = nil, body: Text, image: UIImage?) {
        screenCount += 1
        
        let nestedScrollView = UIScrollView()
        let screen = UIView()
                
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        screen.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(55)
            make.left.right.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(imageView.snp.width).multipliedBy(1.033)
        }
        
        let pageNumber = NumberView(number: screenCount)
        screen.addSubview(pageNumber)
        
        pageNumber.snp.makeConstraints { make in
            make.top.left.equalTo(imageView).inset(UIEdgeInsets(top: 12, left: 20))
        }
        
        let content = UIView()
        screen.addSubview(content)
        
        content.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(-18)
            make.left.right.bottom.equalToSuperview().inset(20)
        }
        
        var contentTopAnchor = content.snp.top
        var contentTopMargin: CGFloat = 0
        
        if let title = title {
            let titleLabel = UILabel(label: self.text(key: title),
                                     font: .heading2,
                                     color: UIColor.Greyscale.black)
            
            titleLabel.numberOfLines = 0
            content.addSubview(titleLabel)
            contentTopAnchor = titleLabel.snp.bottom
            contentTopMargin = 10
            
            titleLabel.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
            }
        }
        
        let label = UILabel(label: body.localized,
                            font: .bodySmall,
                            color: UIColor.Greyscale.darkGrey)
        
        label.numberOfLines = 0
        content.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalTo(contentTopAnchor).offset(contentTopMargin)
            make.left.right.bottom.equalToSuperview()
        }

        stackView.addArrangedSubview(nestedScrollView)
        nestedScrollView.addSubview(screen)
        
        nestedScrollView.snp.makeConstraints { make in
            make.width.height.equalTo(scrollView)
        }

        screen.snp.makeConstraints { make in
            make.edges.equalTo(nestedScrollView.contentLayoutGuide)
            make.width.equalTo(nestedScrollView.frameLayoutGuide)
        }
    }
    
    private func createBottomBar() -> UIView {
        let bottom = UIView()
        bottom.backgroundColor = .white
        bottom.setContentHuggingPriority(.required, for: .vertical)
        view.addSubview(bottom)
        
        bottom.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaInsets)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        secondaryButton = UIButton()
        secondaryButton.setContentHuggingPriority(.required, for: .vertical)
        secondaryButton.setContentCompressionResistancePriority(.required, for: .vertical)
        secondaryButton.titleLabel?.font = .labelTertiary
        secondaryButton.setTitleColor(UIColor.Greyscale.darkGrey, for: .normal)
        secondaryButton.addTarget(self,
                                  action: #selector(secondaryButtonTapped),
                                  for: .touchUpInside)
        
        bottom.addSubview(secondaryButton)
        
        secondaryButton.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(20)
        }
        
        primaryButton = UIButton()
        primaryButton.titleLabel?.font = .labelSecondary
        primaryButton.setTitleColor(UIColor.Primary.blue, for: .normal)
        primaryButton.setTitle(text(key: .ButtonNext), for: .normal)
        primaryButton.addTarget(self,
                                action: #selector(primaryButtonTapped),
                                for: .touchUpInside)
        
        bottom.addSubview(primaryButton)
        
        primaryButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(20)
        }

        pageControl = UIPageControl()
        pageControl.setContentHuggingPriority(.required, for: .vertical)
        pageControl.setContentCompressionResistancePriority(.required, for: .horizontal)
        pageControl.currentPageIndicatorTintColor = UIColor.Primary.blue
        pageControl.pageIndicatorTintColor = UIColor.Greyscale.lightGrey
        pageControl.addTarget(self,
                              action: #selector(pagerValueChanged),
                              for: .valueChanged)
        
        bottom.addSubview(pageControl)
        
        pageControl.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(secondaryButton.snp.right).offset(-20)
            make.right.lessThanOrEqualTo(primaryButton.snp.left).offset(20)
        }

        return bottom
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = page
        pageChanged()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
    private func showPage(index: Int) {
        guard index >= 0 && index < screenCount else {
            return
        }

        let width = scrollView.bounds.width
        let pageRect = CGRect(x: CGFloat(index) * width,
                              y: 0,
                              width: width,
                              height: scrollView.bounds.height)
        
        scrollView.scrollRectToVisible(pageRect, animated: true)
    }
    
    private func pageChanged() {
        let isFirstPage = (pageControl.currentPage == 0)
        let isLastPage = (pageControl.currentPage == screenCount - 1)
        let secondaryTitle: Text = isFirstPage ? .ButtonClose : .ButtonPrevious
        
        secondaryButton.setTitle(text(key: secondaryTitle), for: .normal)
        primaryButton.isHidden = isLastPage
    }
    
    @objc
    func primaryButtonTapped() {
        showPage(index: pageControl.currentPage + 1)
    }

    @objc
    func secondaryButtonTapped() {
        if pageControl.currentPage == 0 {
            close()
        } else {
            showPage(index: pageControl.currentPage - 1)
        }
    }
    
    @objc
    func pagerValueChanged() {
        print("Page value changed to \(pageControl.currentPage)")
        showPage(index: pageControl.currentPage)
    }
    
    @objc
    func close() {
        self.dismiss(animated: true)
    }
}

#if DEBUG

import SwiftUI

struct ExposureGuideViewController_Preview: PreviewProvider {
    static var previews: some View = Group {
        createPreview(for: ExposureGuideViewController())
    }
}

#endif

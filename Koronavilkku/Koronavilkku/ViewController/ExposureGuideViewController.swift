import SnapKit
import UIKit

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
        addScreen(text: .Step1, image: UIImage(named: "exposure-guide-1"))
        addScreen(text: .Step2, image: UIImage(named: "exposure-guide-2"))
        addScreen(text: .Step3, image: UIImage(named: "exposure-guide-3"))
        addScreen(text: .Step4, image: UIImage(named: "exposure-guide-4"))
        addScreen(text: .Step5, image: UIImage(named: "exposure-guide-5"))
        pageControl.numberOfPages = screenCount
        pageChanged()
    }

    private func createUI() {
        let top = createTopBar()
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
            make.top.equalTo(top.snp.bottom)
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
        
        let screen = UIView()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.init(1), for: .vertical)
        screen.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(
                UIEdgeInsets(left: 20, right: 20))
        }
        
        let label = UILabel(label: text.localized,
                            font: .bodySmall,
                            color: UIColor.Greyscale.darkGrey)
        
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        screen.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(20)
            make.top.equalTo(imageView.snp.bottom)
        }

        stackView.addArrangedSubview(screen)

        screen.snp.makeConstraints { make in
            make.width.equalTo(scrollView)
            make.height.equalTo(scrollView)
        }
    }
    
    private func createTopBar() -> UIView {
        let top = UIView()
        top.backgroundColor = UIColor.Greyscale.white
        view.addSubview(top)
        
        top.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalTo(view.safeAreaInsets)
        }
        
        let closeButton = UIButton(type: .close)
        top.addSubview(closeButton)

        closeButton.addTarget(self,
                              action: #selector(self.close),
                              for: .touchUpInside)
        
        closeButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(20)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        let title = UILabel(label: text(key: .Title),
                            font: .heading2,
                            color: UIColor.Greyscale.black)
        
        title.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        title.numberOfLines = 0
        top.addSubview(title)
        
        title.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview().inset(
                UIEdgeInsets(top: 50, left: 20, bottom: 10))
            
            make.right.equalTo(closeButton.snp.left)
        }
        
        return top
    }
    
    private func createBottomBar() -> UIView {
        let bottom = UIView()
        bottom.backgroundColor = .white
        view.addSubview(bottom)
        
        bottom.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaInsets)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        secondaryButton = UIButton()
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

import Foundation
import UIKit
import SnapKit

extension UIView {
    
    func removeAllSubviews() {
        self.subviews.forEach { view in
            view.removeFromSuperview()
        }
    }
    
    func subViewHeight() -> CGFloat {
        return subviews
            .flatMap({ view in view.subviews })
            .reduce(0) { (size, view) in
                size + view.frame.size.height
        }
    }
    
    func addKeyboardDisposer() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing)))
    }
}

extension UIView {
    func elevate() {
        self.layer.shadowColor = UIColor.Greyscale.lightGrey.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 14
    }
}

extension UIView {

    func addScrollableContentView(backgroundColor: UIColor? = nil, margins: UIEdgeInsets) -> UIView {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.backgroundColor = backgroundColor
        addSubview(scrollView)
                
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaInsets)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self.safeAreaInsets)
        }

        let content = UIView()
        scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide.snp.edges).inset(margins)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-margins.horizontal)
        }
        
        return content
    }
    
    func appendView(_ view: UIView, spacing: CGFloat = 0, top: ConstraintItem) -> ConstraintItem {
        addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(top).offset(spacing)
        }
        return view.snp.bottom
    }
    
    static func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor.Greyscale.borderGrey
        
        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }
        
        return divider
    }
}

extension UIView {
    
    static func defaultTransition(with view: UIView, animations: (() -> Void)?) {
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: animations)
    }
}

extension UIEdgeInsets {
    
    var horizontal: CGFloat {
        get { left + right }
    }
    
    var vertical: CGFloat {
        get { top + bottom }
    }
}

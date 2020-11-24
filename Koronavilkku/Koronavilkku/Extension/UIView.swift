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

    func addScrollableContentView(backgroundColor: UIColor? = nil, margins: UIEdgeInsets) -> UIView {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
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
    
    func appendView(_ view: UIView, insets: UIEdgeInsets, top: ConstraintItem) -> ConstraintItem {
        addSubview(view)
        
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(insets)
            make.top.equalTo(top).offset(insets.top)
        }
        
        return view.snp.bottom
    }
    
    static func createDivider(height: CGFloat = 0.5) -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor.Greyscale.borderGrey
        
        divider.snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        
        return divider
    }
    
    @discardableResult
    func layout(appendMaker: ((UIView, UIEdgeInsets?) -> ()) -> ()) -> Self {
        var topAnchor = self.snp.top
        var bottomInset: CGFloat = 0
        
        appendMaker { view, insets in
            var insets = insets ?? UIEdgeInsets()
            insets.top += bottomInset
            topAnchor = appendView(view, insets: insets, top: topAnchor)
            bottomInset = insets.bottom
        }
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(topAnchor).offset(bottomInset)
        }
        
        return self
    }
}

extension UIView {
    
    static func defaultTransition(with view: UIView, animations: (() -> Void)?) {
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: animations)
    }
}

extension UIEdgeInsets {
    init(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) {
        self.init(top: top ?? 0, left: left ?? 0, bottom: bottom ?? 0, right: right ?? 0)
    }
    
    var horizontal: CGFloat {
        get { left + right }
    }
    
    var vertical: CGFloat {
        get { top + bottom }
    }
}

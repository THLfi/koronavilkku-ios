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
    
    func layout(padding: UIEdgeInsets? = nil, appendMaker: ((UIView, UIEdgeInsets?) -> ()) -> ()) {
        var top = self.snp.top
        var paddingTop = padding?.top ?? 0
        
        appendMaker { view, insets in
            var insets = insets ?? UIEdgeInsets()
            
            if let padding = padding {
                insets = UIEdgeInsets(top: insets.top + paddingTop,
                                      left: insets.left + padding.left,
                                      bottom: insets.bottom,
                                      right: insets.right + padding.right)
            }
            
            paddingTop = 0
            top = appendView(view, insets: insets, top: top)
        }
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(top).offset(padding?.bottom ?? 0)
        }
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

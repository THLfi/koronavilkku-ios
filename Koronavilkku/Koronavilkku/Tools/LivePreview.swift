import Foundation

#if DEBUG

import SwiftUI

private struct UIViewControllerPreviewContainer<T: UIViewController> : UIViewControllerRepresentable {
    var viewController: T
    
    func makeUIViewController(context: Context) -> T {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: T, context: Context) {
    }
}

private struct UIViewPreviewContainer<T: UIView> : UIViewRepresentable {
    var view: T
    
    func makeUIView(context: Context) -> T {
        return view
    }
    
    func updateUIView(_ uiView: T, context: Context) {
    }
}

extension PreviewProvider {
    static func createPreview(for viewController: UIViewController) -> some View {
        UIViewControllerPreviewContainer(viewController: viewController)
            .previewDevice(PreviewDevice("iPhone 11 Pro"))
            .edgesIgnoringSafeArea(.all)
    }
    
    static func createPreview(for view: UIView, width: CGFloat, height: CGFloat) -> some View {
        UIViewPreviewContainer(view: view)
            .previewLayout(.fixed(width: width, height: height))
    }
    
    static func createPreviewInContainer(for view: UIView, width: CGFloat, height: CGFloat) -> some View {
        let container = UIView()
        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(20)
        }
        
        return UIViewPreviewContainer(view: container)
            .previewLayout(.fixed(width: width, height: height))
    }
}

#endif

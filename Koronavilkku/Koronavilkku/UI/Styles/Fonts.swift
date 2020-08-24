import Foundation
import UIKit

extension UIFont {
    static var heading1 = useFont(name: "SourceSansPro-Black", ofSize: 34, withStyle: .title1)
    static var heading2 = useFont(name: "SourceSansPro-Black", ofSize: 24, withStyle: .title2)
    static var heading3 = useFont(name: "SourceSansPro-Bold", ofSize: 20, withStyle: .title3)
    static var heading4 = useFont(name: "SourceSansPro-Semibold", ofSize: 18, withStyle: .headline)
    static var heading5 = useFont(name: "SourceSansPro-Semibold", ofSize: 13, withStyle: .subheadline)
    static var labelPrimary = useFont(name: "SourceSansPro-Bold", ofSize: 17, withStyle: .headline)
    static var labelSecondary = useFont(name: "SourceSansPro-Bold", ofSize: 13, withStyle: .caption1)
    static var labelTertiary = useFont(name: "SourceSansPro-Regular", ofSize: 13, withStyle: .caption1)
    static var coronaCode = useFont(name: "SourceSansPro-Regular", ofSize: 24, withStyle: .subheadline)
    static var bodyLarge = useFont(name: "SourceSansPro-Regular", ofSize: 18, withStyle: .body)
    static var bodySmall = useFont(name: "SourceSansPro-Regular", ofSize: 15, withStyle: .body)
    static var searchBarPlaceholder = useFont(name: "SourceSansPro-Regular", ofSize: 17, withStyle: .body)
    static var linkLabel = useFont(name: "SourceSansPro-Bold", ofSize: 15, withStyle: .body)
    static var tabTitle = useFont(name: "SourceSansPro-Semibold", ofSize: 11, withStyle: .caption2)

    static fileprivate func useFont(
        name: String,
        ofSize size: CGFloat,
        withStyle style: TextStyle
    ) -> UIFont {
        return UIFontMetrics(forTextStyle: style).scaledFont(
            for: UIFont(name: name, size: size) ?? systemFont(ofSize: size)
        )
    }
}

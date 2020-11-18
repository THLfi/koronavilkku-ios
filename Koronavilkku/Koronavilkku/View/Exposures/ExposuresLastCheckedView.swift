
import Foundation
import UIKit
import Combine

class ExposuresLastCheckedView: UIView {
    enum Text : String, Localizable {
        case LastCheckedAt
        case MomentAgo
        case NotCheckedYet
    }
    
    enum Style {
        case normal
        case subdued
        
        var font: UIFont {
            switch self {
            case .normal:
                return .bodySmall
            case .subdued:
                return .labelTertiary
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .normal:
                return UIColor.Greyscale.black
            case .subdued:
                return UIColor.Greyscale.darkGrey
            }
        }
    }
    
    private var cancellable: AnyCancellable?
    private var lastCheckedLabel: UILabel!
    private let style: Style
    
    var timeFromLastCheck: TimeInterval? {
        didSet {
            render()
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            lastCheckedLabel.text
        }
        set {}
    }
    
    init(style: Style = .normal, value lastChecked: TimeInterval? = nil) {
        self.timeFromLastCheck = lastChecked
        self.style = style
        
        super.init(frame: .zero)
        
        self.createUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func format(interval: TimeInterval?) -> String {
        guard let interval = interval else {
            return Text.NotCheckedYet.localized
        }
        
        return Text.LastCheckedAt.localized(with: interval > -60
            ? Text.MomentAgo.localized
            : RelativeDateTimeFormatter().localizedString(fromTimeInterval: interval))
    }

    private func bindViewModel() {
        cancellable = Environment.default.exposureRepository.timeFromLastCheck()
            .map(Self.format)
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: lastCheckedLabel)
    }
    
    private func createUI() {
        lastCheckedLabel = UILabel(label: "", font: style.font, color: style.textColor)
        lastCheckedLabel.numberOfLines = 0
        self.addSubview(lastCheckedLabel)
        
        lastCheckedLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        render()
    }
    
    private func render() {
        lastCheckedLabel.text = Self.format(interval: timeFromLastCheck)
    }
}

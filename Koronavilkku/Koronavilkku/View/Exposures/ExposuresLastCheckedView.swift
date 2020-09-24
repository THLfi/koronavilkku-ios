
import Foundation
import UIKit
import Combine

class ExposuresLastCheckedView: UIView {
    enum Text : String, Localizable {
        case NotCheckedYet
        case LastCheckedAt
    }
    
    private var cancellable: AnyCancellable?
    private var lastCheckedLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        self.bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel() {
        cancellable = LocalStore.shared.$dateLastPerformedExposureDetection.$wrappedValue
            .map { lastChecked in
                guard let date = lastChecked else {
                    return Text.NotCheckedYet.localized
                }
                
                return Text.LastCheckedAt.localized(with: date.toLocalizedRelativeFormat())
            }
            .sink( receiveValue: { lastCheckedString in
                DispatchQueue.main.async {
                    self.updateUI(label: lastCheckedString)
                }
            })
    }
    
    private func updateUI(label: String) {
        self.removeAllSubviews()
        
        lastCheckedLabel = UILabel(label: label,
                                   font: UIFont.bodySmall,
                                   color: UIColor.Greyscale.black)
        lastCheckedLabel.numberOfLines = 0
        self.addSubview(lastCheckedLabel)
        
        lastCheckedLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

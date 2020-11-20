import Combine
import UIKit
import SnapKit

class NotificationListViewController: UIViewController {
    
    enum Text: String, Localizable {
        case Title
        case Disclaimer
        case ItemTitle
        case ItemCountLabel
        case ItemCountValue
        case ItemIntervalLabel
        case ItemIntervalValue
    }
    
    private var notificationListWrapper: UIView!
    private var lastCheckedView: ExposuresLastCheckedView!
    private var updateTasks = Set<AnyCancellable>()
    private let exposureRepository: ExposureRepository
    
    init(env: Environment = .default) {
        exposureRepository = env.exposureRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initDataBinding()
    }
    
    private func initUI() {
        let content = view.addScrollableContentView(
            backgroundColor: UIColor.Secondary.blueBackdrop,
            margins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        let closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        let titleView = UILabel(label: Text.Title.localized,
                                font: .heading2,
                                color: UIColor.Greyscale.black)

        titleView.numberOfLines = 0
        
        lastCheckedView = ExposuresLastCheckedView(style: .normal, value: nil)
        notificationListWrapper = UIView()

        let disclaimerView = UILabel(label: Text.Disclaimer.localized,
                                     font: .bodySmall,
                                     color: UIColor.Greyscale.darkGrey)
        
        disclaimerView.numberOfLines = 0

        content.layout(padding: UIEdgeInsets(top: 20, bottom: 50)) { append in
            append(titleView, UIEdgeInsets(right: 40))
            append(lastCheckedView, UIEdgeInsets(top: 6))
            append(notificationListWrapper, UIEdgeInsets())
            append(disclaimerView, UIEdgeInsets(top: 20))
        }
    }
    
    private func initDataBinding() {
        exposureRepository.getExposureNotifications()
            .sink { [weak self] notifications in
                guard let self = self else { return }
                
                self.notificationListWrapper.removeAllSubviews()
                
                var top = self.notificationListWrapper.snp.top
                var bottom: ConstraintItem? = nil
                
                for notification in notifications.sorted(by: { $0.detectedOn > $1.detectedOn }) {
                    let item = self.createNotificationItem(notification: notification)
                    top = self.notificationListWrapper.appendView(item, spacing: 20, top: top)
                    bottom = item.snp.bottom
                }
                
                if let bottom = bottom {
                    self.notificationListWrapper.snp.makeConstraints { make in
                        make.bottom.equalTo(bottom)
                    }
                }
            }
            .store(in: &updateTasks)
        
        exposureRepository.timeFromLastCheck()
            .sink { [weak self] time in
                self?.lastCheckedView.timeFromLastCheck = time
            }
            .store(in: &updateTasks)
    }
    
    func createNotificationItem(notification: ExposureNotification) -> CardElement {
        let card = CardElement()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMyyyy")
        let title = UILabel(label: Text.ItemTitle.localized(with: formatter.string(from: notification.detectedOn)),
                            font: .heading4,
                            color: UIColor.Greyscale.black)

        title.numberOfLines = 0
        
        card.layout(padding: .init(top: 20, left: 20, bottom: 20, right: 20)) { append in
            append(title, nil)
            append(.createDivider(height: 1), UIEdgeInsets(top: 10))
            
            append(addLine(label: Text.ItemCountLabel.localized,
                           value: Text.ItemCountValue.localized(with: String(notification.exposureCount))),
                   UIEdgeInsets(top: 10))
            
            let formatter = DateIntervalFormatter()
            formatter.timeStyle = .none
            
            let interval = formatter.string(from: notification.detectionInterval.start,
                                            to: notification.detectionInterval.end)
            
            append(addLine(label: Text.ItemIntervalLabel.localized,
                           value: Text.ItemIntervalValue.localized(with: interval)),
                   UIEdgeInsets(top: 10))
        }

        return card
    }
    
    private func addLine(label: String, value: String) -> UIView {
        let line = UIView()
        
        let label = UILabel(label: label, font: .bodySmall, color: UIColor.Greyscale.black)
        label.numberOfLines = 0
        label.textAlignment = .left
        line.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
        }
        
        let value = UILabel(label: value, font: .bodySmall, color: UIColor.Greyscale.black)
        value.numberOfLines = 0
        value.textAlignment = .right
        line.addSubview(value)
        
        value.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(label.snp.right)
        }
        
        return line
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: {})
    }
}

#if DEBUG
import SwiftUI

struct NotificationListViewController_Preview: PreviewProvider {
    static var previews: some View = createPreviewInNavController(for: NotificationListViewController(env: .preview {
        PreviewState(
            timeFromLastCheck: Just(-10_000),
            exposureNotifications: Just(
                [
                    ExposureNotification(detectionTime: Date(timeIntervalSince1970: 1_609_700_000),
                                         latestExposureOn: Date(),
                                         exposureCount: 1),
                    
                    ExposureNotification(detectionTime: Date(),
                                         latestExposureOn: Date(),
                                         exposureCount: 5),
                    
                    ExposureNotification(detectionTime: Date().addingTimeInterval(86_400 * -1),
                                         latestExposureOn: Date(),
                                         exposureCount: 3),
                ]))
    }))
}
#endif

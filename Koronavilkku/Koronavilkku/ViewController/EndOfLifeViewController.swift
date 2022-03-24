import UIKit
import Combine
import SnapKit


class EndOfLifeViewController: UIViewController {
    
    let radarImageView = UIImageView()
    let logoImageView = UIImageView()
    
    let titleLabel = UILabel()
    let textLabel = UILabel()
    

    var stackView = UIStackView()
    
    var radarImage = UIImage(named: "radar-off")
    var logoImage = UIImage(named: "THL-logo")
    
    var titleText = Translation.EndOfLifeTitle.localized
    var textLabelText = Translation.EndOfLifeMessage.localized
    
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
    }
    
    private func createUI() {
        
        let locale = Locale.current.languageCode

        let margin = UIEdgeInsets(top: 20, left: 20, bottom: 30, right: 20)
        let containerView = view.addScrollableContentView(backgroundColor: UIColor.Secondary.blueBackdrop,
                            margins: margin)
        var top = containerView.snp.top
        
        //Setup header view
        radarImageView.image = radarImage
        radarImageView.contentMode = .scaleAspectFit
        top = containerView.appendView(radarImageView, top: top)
        
        //Setup title
        titleLabel.text = titleText
        titleLabel.font = .heading2
        titleLabel.numberOfLines = 0
        top = containerView.appendView(titleLabel, spacing: 20, top: top)
        
        //Setup description
        textLabel.text = textLabelText
        textLabel.font = UIFont.bodyLarge
        textLabel.numberOfLines = 0
        top = containerView.appendView(textLabel, spacing: 20, top: top)
        
        //Setup Statistics card
        stackView.axis = .vertical
        stackView.spacing = 10.0
        containerView.addSubview(stackView)
        
        for stat in LocalStore.shared.endOfLifeStatisticsData {
            switch locale {
                case "fi":
                    let statisticsElement = StatisticsCard(title: stat.value.fi, body: stat.label.fi)
                    stackView.addArrangedSubview(statisticsElement)
                case "sv":
                    let statisticsElement = StatisticsCard(title: stat.value.sv, body: stat.label.sv)
                    stackView.addArrangedSubview(statisticsElement)
                default:
                    let statisticsElement = StatisticsCard(title: stat.value.en, body: stat.label.en)
                    stackView.addArrangedSubview(statisticsElement)
            }
        }
    
        top = containerView.appendView(stackView, spacing: 20, top: top)
        
        //Setup footer
        logoImageView.image = logoImage
        logoImageView.contentMode = .scaleAspectFit
        top = containerView.appendView(logoImageView, spacing: 30, top: top)
        
        logoImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
 
    }
         
}

import SnapKit
import UIKit

class LicenseListViewController : UITableViewController {
    enum Text : String, Localizable {
        case Title
    }
    
    enum Dependency : String, CaseIterable {
        case SnapKit
        case TrustKit
        case ZIPFoundation
        
        var license: String {
            Bundle.main.localizedString(forKey: rawValue, value: nil, table: "Licenses")
        }
    }
    
    let tableViewCellIdentifier = "LicenseListCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
        title = Text.Title.localized

        tableView.backgroundColor = UIColor.Secondary.blueBackdrop
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 62
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        10
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Dependency.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(
            LicenseViewController(dependency: Dependency.allCases[indexPath.row]),
            animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        cell.backgroundColor = UIColor.Secondary.blueBackdrop
        cell.accessoryType = .disclosureIndicator

        if let label = cell.textLabel {
            label.text = Dependency.allCases[indexPath.row].rawValue
            label.font = .bodySmall
            label.numberOfLines = -1
            
            label.snp.remakeConstraints { make in
                make.top.left.bottom.right.equalToSuperview().inset(20)
            }
        }

        return cell
    }
}

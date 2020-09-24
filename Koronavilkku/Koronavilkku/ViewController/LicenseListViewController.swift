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
        
        if let appearance = navigationController?.navigationBar.standardAppearance.copy() {
            appearance.largeTitleTextAttributes = [
                .font: UIFont.heading2
            ]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = Text.Title.localized
        navigationItem.backButtonTitle = ""

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
        cell.textLabel?.text = Dependency.allCases[indexPath.row].rawValue
        cell.textLabel?.font = .bodySmall
        cell.textLabel?.numberOfLines = -1
        
        cell.textLabel?.snp.remakeConstraints { make in
            make.top.left.bottom.right.equalToSuperview().inset(20)
        }

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

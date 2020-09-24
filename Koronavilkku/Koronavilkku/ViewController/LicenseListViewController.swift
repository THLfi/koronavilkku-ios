import SnapKit
import UIKit

class LicenseListViewController : UITableViewController {
    enum Dependency : String, CaseIterable {
        case SnapKit
        case TrustKit
        case ZIPFoundation
        
        var license: String {
            Bundle.main.localizedString(forKey: rawValue, value: nil, table: "Licenses")
        }
    }
    
    let tableViewCell = "LicenseCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.backgroundColor = UIColor.Secondary.blueBackdrop
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCell)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let heading = UIView()
        heading.backgroundColor = UIColor.Secondary.blueBackdrop
        
        let title = UILabel(label: "Avoimen lähdekoodin lisenssit", font: .heading2, color: UIColor.Greyscale.black)
        title.numberOfLines = -1
        heading.addSubview(title)
        
        title.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().inset(20)
        }
        
        return heading
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Dependency.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCell, for: indexPath)
        cell.backgroundColor = UIColor.Secondary.blueBackdrop
        cell.textLabel?.text = Dependency.allCases[indexPath.row].rawValue
        cell.textLabel?.font = .bodySmall
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

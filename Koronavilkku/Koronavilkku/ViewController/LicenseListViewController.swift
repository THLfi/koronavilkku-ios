import SnapKit
import UIKit

class LicenseListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
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
        
        title = ""
        view.backgroundColor = UIColor.Secondary.blueBackdrop
        navigationItem.largeTitleDisplayMode = .never

        let title = UILabel(label: "Avoimen lähdekoodin lisenssit", font: .heading2, color: UIColor.Greyscale.black)
        title.numberOfLines = -1
        view.addSubview(title)
        
        title.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.safeAreaLayoutGuide).inset(25)
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 62
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Dependency.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(LicenseViewController(dependency: Dependency.allCases[indexPath.row]), animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

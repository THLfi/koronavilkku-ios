
import Foundation
import UIKit

class MunicipalitySearchResultController: UITableViewController {
    
    let tableViewCellIdentifier = "MunicipalitySearchResultTableCell"
    
    var filteredMunicipalities: Municipalities = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
        tableView.dataSource = self
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMunicipalities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        let municipality = filteredMunicipalities[indexPath.row]
        cell.textLabel?.text = municipality.name.localeString
        return cell
    }
}

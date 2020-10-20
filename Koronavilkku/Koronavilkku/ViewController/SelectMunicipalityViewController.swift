import Foundation
import UIKit
import Combine

class SelectMunicipalityViewController: UITableViewController {
    enum Text : String, Localizable {
        case Title
        case SearchPlaceholder
        case ErrorTitle
        case ErrorMessage
        case ErrorButton
    }
    
    private let tableViewCellId = "MunicipalityTableViewCellId"
    private let tableViewHeaderId = "MunicipalityTableViewHeaderId"
    
    private var searchController: UISearchController!
    private var resultsTableController: MunicipalitySearchResultController!
    
    private var municipalities: Municipalities = []
    private var municipalitiesByName: [(key: Character, value: Municipalities)] = []
    
    private let municipalityRepository = Environment.default.municipalityRepository
    private var loadTask: AnyCancellable?
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        tableView.register(MunicipalityCell.self, forCellReuseIdentifier: tableViewCellId)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: tableViewHeaderId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        setupSearchController()
        
        self.view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        activityIndicator.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.title = Text.Title.localized
        navigationItem.largeTitleDisplayMode = .never

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.barTintColor = UIColor.Secondary.blueBackdrop
        navigationController?.navigationBar.tintColor = UIColor.Primary.blue
        
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.Greyscale.black,
            NSAttributedString.Key.font: UIFont.labelPrimary
        ]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        createLoadTask()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    private func setupSearchController() {
        
        resultsTableController = MunicipalitySearchResultController(style: .plain)
        resultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.searchTextField.placeholder = Text.SearchPlaceholder.localized
        searchController.searchBar.searchTextField.font = UIFont.searchBarPlaceholder
        searchController.searchBar.backgroundColor = UIColor.Secondary.blueBackdrop
        
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func createLoadTask() {
        loadTask = municipalityRepository.getMunicipalityList()
        .sink(receiveCompletion: { result in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            }
            switch result {
            case .finished:
                Log.d("get municipality completed")
            case .failure(let error):
                Log.e(error)
                self.showAlert(title: Text.ErrorTitle.localized,
                               message: Text.ErrorMessage.localized,
                               buttonText: Text.ErrorButton.localized) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }, receiveValue: {
            self.municipalities = $0
            self.municipalitiesByName = Dictionary(grouping: self.municipalities,
                                                   by: { $0.name.localeString.first! }).sorted(by: { $0.key < $1.key })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
        
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let municipality: Municipality
        if tableView === self.tableView {
            municipality = municipalitiesByName[indexPath.section].value[indexPath.row]
        } else {
            municipality = resultsTableController.filteredMunicipalities[indexPath.row]
        }
        
        let municipalityVC = MunicipalityContactInfoViewController()
        municipalityVC.municipality = municipality
        self.navigationController?.pushViewController(municipalityVC, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return municipalitiesByName[section].value.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return municipalitiesByName.count
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return municipalitiesByName.map { $0.key.uppercased() }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellId, for: indexPath)
        cell.textLabel?.text = municipalitiesByName[indexPath.section].value[indexPath.row].name.localeString
        cell.textLabel?.font = UIFont.bodySmall
        cell.backgroundColor = UIColor.Greyscale.white
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView === resultsTableController.tableView { return nil }
        var header = tableView.dequeueReusableHeaderFooterView(withIdentifier: tableViewHeaderId)
        if header == nil {
            header = UITableViewHeaderFooterView(reuseIdentifier: tableViewHeaderId)
        }
        header?.textLabel?.font = UIFont.heading4
        header?.textLabel?.text = municipalitiesByName[section].key.uppercased()
        header?.textLabel?.backgroundColor = UIColor.Secondary.tableHeaderBackground
        header?.contentView.backgroundColor = UIColor.Secondary.tableHeaderBackground
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView === resultsTableController.tableView { return .leastNormalMagnitude }
        return 28
    }
}

extension SelectMunicipalityViewController: UISearchControllerDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}
extension SelectMunicipalityViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? nil
        guard let _ = searchString else { return }
        let filtered = self.municipalities.filter { $0.name.localeString.lowercased().contains(searchString!.lowercased()) }
        resultsTableController.filteredMunicipalities = filtered
        resultsTableController.tableView.reloadData()
    }
}
extension SelectMunicipalityViewController: UISearchBarDelegate {}

#if DEBUG
import SwiftUI

struct SelectMunicipalityViewControllerPreview: PreviewProvider {
    static var previews: some View = createPreview(for:
        UINavigationController(rootViewController: SelectMunicipalityViewController(style: .plain)))
}
#endif

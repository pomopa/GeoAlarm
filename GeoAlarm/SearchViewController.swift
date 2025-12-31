//
//  SearchViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//

import UIKit
import MapKit

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDropdownButtons()
        configureSearch()
        configureTableView()
    }
    
    // --------------------------------------------
    // Configurations
    // --------------------------------------------
    private func configureSearch() {
        searchBar.delegate = self
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
    }
    
    func configureDropdownButtons() {
        let units = ["km", "m", "mi", "ft"]

        let actions = units.map { unit in
            UIAction(title: unit) { _ in
                self.unitButton.setTitle(unit, for: .normal)
            }
        }

        unitButton.menu = UIMenu(title: "Units", children: actions)
        unitButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let location = searchBar.text ?? ""
        let radius = radiusTextField.text ?? ""
        let unit = unitButton.title(for: .normal) ?? ""

        print("Location: \(location), Radius: \(radius) \(unit)")
    }
    
}

extension SearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            tableView.isHidden = true
            searchResults.removeAll()
            tableView.reloadData()
        } else {
            searchCompleter.queryFragment = searchText
        }
    }
}

extension SearchViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.isHidden = searchResults.isEmpty
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error:", error.localizedDescription)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let result = searchResults[indexPath.row]

        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let result = searchResults[indexPath.row]
        searchBar.text = result.title
        tableView.isHidden = true
        searchBar.resignFirstResponder()
    }
}


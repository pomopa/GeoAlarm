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
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedCompletion: MKLocalSearchCompletion?
    private let locationSearchService = LocationSearchService()
    private let decimalDelegate = DecimalTextFieldDelegate(maxDecimals: 3)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitButton.configureDropdown(options: ["km", "m", "mi", "ft"]) { [weak self] selectedUnit in
            self?.unitButton.setTitle(selectedUnit, for: .normal)
            self?.maxRadiusLabel.text = RadiusHelper.radiusText(for: selectedUnit)
        }
        configureSearch()
        configureTableView()
        tableViewHeightConstraint.constant = 0
        hideKeyboardWhenTappedAround()
        radiusTextField.delegate = decimalDelegate
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
    
    // --------------------------------------------
    // Helpers
    // --------------------------------------------
    private func didSelectSearchResult(_ result: MKLocalSearchCompletion) {
        selectedCompletion = result
        searchBar.text = result.title

        searchResults.removeAll()
        tableView.reloadData()

        tableView.isHidden = true
        tableViewHeightConstraint.constant = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }

        searchBar.resignFirstResponder()
    }
    
    // --------------------------------------------
    // Add alarm
    // --------------------------------------------
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Validate location selection
        guard let selectedCompletion = selectedCompletion else {
            showAlert(title: NSLocalizedString("missing_location", comment: ""), message: NSLocalizedString("select_location", comment: ""))
            return
        }

        // Validate radius
        guard let radiusText = radiusTextField.text,
                let radius = Double(radiusText),
                radius > 0 else {
            showAlert(title: NSLocalizedString("invalid_radius", comment: ""), message: NSLocalizedString("enter_valid_radius", comment: "")
                      )
            return
        }

        let unit = unitButton.title(for: .normal) ?? "km"

        // Resolve coordinates
        locationSearchService.resolve(completion: selectedCompletion) { [weak self] coordinate in
            guard let self else { return }

            guard let coordinate else {
                self.showAlert(title: "Error", message: NSLocalizedString("cant_resolve", comment: ""))
                return
            }

            FirestoreHelper.fetchActiveAlarmCount { activeCount in
                let canActivate = activeCount < 20

                FirestoreHelper.saveOrUpdateAlarm(
                    locationName: selectedCompletion.title,
                    coordinate: coordinate,
                    radius: radius,
                    unit: unit,
                    isActive: canActivate
                ) { result in

                    switch result {
                    case .failure(let error):
                        self.showAlert(
                            title: "Error",
                            message: error.localizedDescription
                        )

                    case .success:
                        self.searchBar.text = ""
                        self.radiusTextField.text = ""
                        
                        if canActivate {
                            self.showAlert(
                                title: NSLocalizedString("alarm_success_title", comment:""),
                                message: NSLocalizedString("alarm_success_message", comment: "")
                            )
                        } else {
                            self.showAlert(
                                title: NSLocalizedString("alarm_inactive_title", comment: ""),
                                message: NSLocalizedString("alarm_inactive_message", comment: "")
                            )
                        }
                    }
                }
            }
        }
    }
}


// --------------------------------------------
// Delegates and Data Sources
// --------------------------------------------
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            tableView.isHidden = true
            searchResults.removeAll()
            tableView.reloadData()
            updateTableViewHeight(
                rows: 0,
                constraint: tableViewHeightConstraint
            )
        } else {
            searchCompleter.queryFragment = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let firstResult = searchResults.first else {
            return
        }

        didSelectSearchResult(firstResult)
    }
}

extension SearchViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        updateTableViewHeight(
            rows: searchResults.count,
            constraint: tableViewHeightConstraint
        )
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
        didSelectSearchResult(result)
    }
}

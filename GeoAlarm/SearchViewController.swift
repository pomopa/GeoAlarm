//
//  SearchViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//

import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedCompletion: MKLocalSearchCompletion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDropdownButtons()
        configureSearch()
        configureTableView()
        tableViewHeightConstraint.constant = 0
        hideKeyboardWhenTappedAround()
    }
    
    // --------------------------------------------
    // Configurations
    // --------------------------------------------
    private func configureSearch() {
        searchBar.delegate = self
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    private func updateTableViewHeight() {
        let test = min(tableView.contentSize.height, 200)
        print("value height is \(test)")
        tableViewHeightConstraint.constant = min(tableView.contentSize.height, 200)
               
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
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
    
    // --------------------------------------------
    // Helpers
    // --------------------------------------------
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func resolveLocation(
        completion: MKLocalSearchCompletion,
        completionHandler: @escaping (CLLocationCoordinate2D?) -> Void
    ) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let coordinate = response?
                .mapItems.first?
                .location
                .coordinate else {
                completionHandler(nil)
                return
            }

            completionHandler(coordinate)
        }
    }


    private func saveAlarm(
        locationName: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        unit: String
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert("Error", "User not logged in")
            return
        }

        let db = Firestore.firestore()

        let alarmData: [String: Any] = [
            "locationName": locationName,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radius": radius,
            "unit": unit,
            "isActive": true,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("users")
            .document(userId)
            .collection("alarms")
            .addDocument(data: alarmData) { error in

                if let error = error {
                    self.showAlert("Error", error.localizedDescription)
                } else {
                    self.showAlert("Success", "Alarm saved")
                }
            }
    }
    
    // --------------------------------------------
    // Add alarm
    // --------------------------------------------
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Validate location selection
        guard let selectedCompletion = selectedCompletion else {
            showAlert("Missing location", "Please select a location from the list")
            return
        }

        // Validate radius
        guard let radiusText = radiusTextField.text,
                let radius = Double(radiusText),
                radius > 0 else {
            showAlert("Invalid radius", "Please enter a valid radius")
            return
            }

        let unit = unitButton.title(for: .normal) ?? "km"

        // Resolve coordinates
        resolveLocation(completion: selectedCompletion) { coordinate in
            guard let coordinate = coordinate else {
                self.showAlert("Error", "Unable to resolve location")
                return
            }

            // Save to Firebase
            self.saveAlarm(
                locationName: selectedCompletion.title,
                coordinate: coordinate,
                radius: radius,
                unit: unit
            )
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
            updateTableViewHeight()
        } else {
            searchCompleter.queryFragment = searchText
            updateTableViewHeight()
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
        selectedCompletion = result
        
        searchBar.text = result.title
        tableView.isHidden = true
        searchBar.resignFirstResponder()
    }
}


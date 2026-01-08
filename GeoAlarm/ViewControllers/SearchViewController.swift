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
        unitButton.configureDropdown(
            options: ["km", "m", "mi", "ft"]
        )
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
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
    }
    
    // --------------------------------------------
    // Helpers
    // --------------------------------------------
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

    private func saveAlarm(
        locationName: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        unit: String
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "User not logged in")
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
                    self.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "Success", message: "Alarm saved")
                }
            }
        let regions = LocationManager.shared.getFences()

        print("Hi ha \(regions.count) geofences actius:")

        for region in regions {
            print("• \(region.identifier)")
        }

        print("addedd Alarm \(locationName) at \(Timestamp(date: Date()))")
        
        var radiusInMeters: Double

        if unit == "m" {
            radiusInMeters = radius
        } else if unit == "km" {
            radiusInMeters = radius * 1000
        } else if unit == "mi" {
            radiusInMeters = radius * 1609.34
        } else if unit == "ft" {
            radiusInMeters = radius * 0.3048
        } else {
            radiusInMeters = radius
        }
        
        LocationManager.shared.addGeofence(
            id: "Alarm \(locationName) at \(Timestamp(date: Date()))",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: radiusInMeters
            )
    }
    
    // --------------------------------------------
    // Add alarm
    // --------------------------------------------
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Validate location selection
        guard let selectedCompletion = selectedCompletion else {
            showAlert(title: "Missing location", message: "Please select a location from the list")
            return
        }

        // Validate radius
        guard let radiusText = radiusTextField.text,
                let radius = Double(radiusText),
                radius > 0 else {
            showAlert(title: "Invalid radius", message: "Please enter a valid radius")
            return
            }

        let unit = unitButton.title(for: .normal) ?? "km"

        // Resolve coordinates
        resolveLocation(completion: selectedCompletion) { coordinate in
            guard let coordinate = coordinate else {
                self.showAlert(title: "Error", message: "Unable to resolve location")
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

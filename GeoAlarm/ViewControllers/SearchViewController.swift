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
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedCompletion: MKLocalSearchCompletion?
    private let locationSearchService = LocationSearchService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitButton.configureDropdown(options: ["km", "m", "mi", "ft"]) { [weak self] selectedUnit in
            self?.unitButton.setTitle(selectedUnit, for: .normal)
            self?.maxRadiusLabel.text = RadiusHelper.maxRadiusText(for: selectedUnit)
        }
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
    
    private func fetchActiveAlarmCount(
        completion: @escaping (Int) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("alarms")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, _ in
                completion(snapshot?.documents.count ?? 0)
            }
    }

    private func saveAlarm(
        locationName: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        unit: String,
        isActive: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "User not logged in")
            return
        }

        let radiusInMeters = RadiusHelper.calculateRadiusInMeters(unit: unit, value: radius)
        let maxRadius = RadiusHelper.maxRadius(for: unit)
        guard radiusInMeters <= 1000 else {
            let message = String(format: "The maximum allowed radius for %@ is %.2f %@", unit, maxRadius, unit)
            showAlert(title: "Invalid radius", message: message)
            return
        }
        
        let db = Firestore.firestore()
        
        let alarmRef = db
            .collection("users")
            .document(userId)
            .collection("alarms")
            .document()
        
        let alarmID = alarmRef.documentID
        
        let alarmData: [String: Any] = [
            "locationName": locationName,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radius": radius,
            "unit": unit,
            "isActive": isActive,
            "createdAt": Timestamp(date: Date())
        ]

        alarmRef.setData(alarmData) { error in
            if let error {
                completion(.failure(error))
                return
            }

            if isActive {
                LocationManager.shared.addGeofence(
                    id: alarmID,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: radiusInMeters
                )
            }
            
            completion(.success(()))
        }
        
        searchBar.text = ""
        radiusTextField.text = ""
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
        locationSearchService.resolve(completion: selectedCompletion) { [weak self] coordinate in
            guard let self else { return }

            guard let coordinate else {
                self.showAlert(title: "Error", message: "Unable to resolve location")
                return
            }

            self.fetchActiveAlarmCount { activeCount in
                let canActivate = activeCount < 20

                self.saveAlarm(
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
                        if canActivate {
                            self.showAlert(
                                title: "Success",
                                message: """
                                Alarm saved and activated
                                ⚠️ Will play only when silent mode is off ⚠️
                                """
                            )
                        } else {
                            self.showAlert(
                                title: "Alarm created but inactive",
                                message: """
                                Apple enforces a limit of 20 active simultaneous alarms.
                                This alarm was saved but is inactive.
                                Disable another alarm to activate it.
                                """
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

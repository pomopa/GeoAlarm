//
//  EditAlarmViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 5/1/26.
//
import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore

class EditAlarmViewController: UIViewController {

    var alarm: Alarm!

    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedCompletion: MKLocalSearchCompletion?
    private var currentCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        populateUI()
        configureDropdownButtons()
        configureSearch()
        configureTableView()
        tableViewHeightConstraint.constant = 0
        hideKeyboardWhenTappedAround()
    }
    
    // --------------------------------------------
    // Configurations
    // --------------------------------------------
    func configureDropdownButtons() {
        let units = ["km", "m", "mi", "ft"]

        let actions = units.map { unit in
            UIAction(title: unit) { [weak self] _ in
                self?.unitButton.setTitle(unit, for: .normal)
            }
        }

        unitButton.menu = UIMenu(title: "Units", children: actions)
        unitButton.showsMenuAsPrimaryAction = true
    }

    private func populateUI() {
        nameSearchBar.text = alarm.locationName
        radiusTextField.text = "\(Int(alarm.radius))"
        unitButton.setTitle(alarm.unit, for: .normal)
        currentCoordinate = CLLocationCoordinate2D(latitude: alarm.latitude,
                                                   longitude: alarm.longitude)
    }
    
    private func configureSearch() {
        nameSearchBar.delegate = self
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
    private func updateTableViewHeight(rows: Int ) {
        let height = min(
            60 * CGFloat(rows),
            200
        )
        tableViewHeightConstraint.constant = min(height, 200)
               
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func didSelectSearchResult(_ result: MKLocalSearchCompletion) {
        selectedCompletion = result
        nameSearchBar.text = result.title

        resolveLocation(completion: result) { coordinate in
            self.currentCoordinate = coordinate
        }

        searchResults.removeAll()
        tableView.reloadData()
        tableView.isHidden = true
        tableViewHeightConstraint.constant = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }

        nameSearchBar.resignFirstResponder()
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
    
    private func editAlarm(
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
            "unit": unit
        ]

        db.collection("users")
            .document(userId)
            .collection("alarms")
            .document(alarm.id)
            .updateData(alarmData) { error in

                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true)
                    }
                }
            }
    }


    // --------------------------------------------
    // Button Actions
    // --------------------------------------------
    @IBAction func saveTapped(_ sender: Any) {
        guard let radiusText = radiusTextField.text,
              let radius = Double(radiusText),
              radius > 0 else {
            showAlert(title: "Invalid radius", message: "Please enter a valid radius")
            return
        }

        let unit = unitButton.title(for: .normal) ?? "km"
        let locationName = nameSearchBar.text ?? alarm.locationName
        guard let coordinate = currentCoordinate else {
            showAlert(title: "Missing location", message: "Please select a location from the list")
            return
        }

        let locationChanged = (coordinate.latitude != alarm.latitude) || (coordinate.longitude != alarm.longitude)
        let nameChanged = locationName != alarm.locationName
        let radiusChanged = radius != alarm.radius
        let unitChanged = unit != alarm.unit

        if !locationChanged && !nameChanged && !radiusChanged && !unitChanged {
            self.dismiss(animated: true)
            return
        }

        editAlarm(locationName: locationName,
                  coordinate: coordinate,
                  radius: radius,
                  unit: unit)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func deleteTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Alarm",
            message: "This action cannot be undone",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteAlarm()
        })

        present(alert, animated: true)
    }

    private func deleteAlarm() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "User not logged in")
            return
        }

        let db = Firestore.firestore()
        
        db.collection("users")
            .document(userId)
            .collection("alarms")
            .document(alarm.id)
            .delete { error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
    }
}

// --------------------------------------------
// Delegates and Data Sources
// --------------------------------------------
extension EditAlarmViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            tableView.isHidden = true
            searchResults.removeAll()
            tableView.reloadData()
            updateTableViewHeight(rows: 0)
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

extension EditAlarmViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        updateTableViewHeight(rows: searchResults.count)
        tableView.isHidden = searchResults.isEmpty
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error:", error.localizedDescription)
    }
}

extension EditAlarmViewController: UITableViewDataSource, UITableViewDelegate {

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

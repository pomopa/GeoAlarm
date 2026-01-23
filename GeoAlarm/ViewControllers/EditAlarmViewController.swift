//
//  EditAlarmViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 5/1/26.
//
import UIKit
import MapKit

class EditAlarmViewController: UIViewController {

    var alarm: Alarm!

    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedCompletion: MKLocalSearchCompletion?
    private var currentCoordinate: CLLocationCoordinate2D?
    private let locationSearchService = LocationSearchService()
    private let decimalDelegate = DecimalTextFieldDelegate(maxDecimals: 3)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateUI()
        unitButton.configureDropdown(options: ["km", "m", "mi", "ft"]) { [weak self] selectedUnit in
            self?.unitButton.setTitle(selectedUnit, for: .normal)
            self?.maxRadiusLabel.text = RadiusHelper.radiusText(for: selectedUnit)
        }
        
        configureSearch()
        configureTableView()
        tableViewHeightConstraint.constant = 0
        
        radiusTextField.delegate = decimalDelegate
        hideKeyboardWhenTappedAround()
    }
    
    // --------------------------------------------
    // Configurations
    // --------------------------------------------
    private func populateUI() {
        nameSearchBar.text = alarm.locationName
        let radius = alarm.radius
        if floor(radius) == radius {
            radiusTextField.text = String(format: "%.0f", radius)
        } else {
            radiusTextField.text = String(radius)
        }
        unitButton.setTitle(alarm.unit, for: .normal)
        currentCoordinate = CLLocationCoordinate2D(latitude: alarm.latitude,
                                                   longitude: alarm.longitude)
        maxRadiusLabel.text = RadiusHelper.radiusText(for: alarm.unit)
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
    private func didSelectSearchResult(_ result: MKLocalSearchCompletion) {
        selectedCompletion = result
        nameSearchBar.text = result.title
        
        locationSearchService.resolve(completion: result) { coordinate in
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

    // --------------------------------------------
    // Button Actions
    // --------------------------------------------
    @IBAction func saveTapped(_ sender: Any) {
        guard let radiusText = radiusTextField.text,
              let radius = Double(radiusText),
              radius > 0 else {
            showAlert(title: NSLocalizedString("invalid_radius", comment:""), message: NSLocalizedString("enter_valid_radius", comment:"")
            )
            return
        }

        let unit = unitButton.title(for: .normal) ?? "km"
        let locationName = nameSearchBar.text ?? alarm.locationName
        guard let coordinate = currentCoordinate else {
            showAlert(title: NSLocalizedString("missing_location", comment:""), message: NSLocalizedString("location_from_list", comment:"")
            )
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

        FirestoreHelper.saveOrUpdateAlarm(
            alarmID: alarm.id,
            locationName: locationName,
            coordinate: coordinate,
            radius: radius,
            unit: unit
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.dismiss(animated: true)
                    
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func deleteTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: NSLocalizedString("delete_alarm", comment: ""),
            message: NSLocalizedString("irreversible", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""),style: .cancel))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive) { [weak self] _ in
            guard let self else { return }

            FirestoreHelper.deleteAlarm(alarmID: self.alarm.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })

        present(alert, animated: true)
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

extension EditAlarmViewController: MKLocalSearchCompleterDelegate {
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

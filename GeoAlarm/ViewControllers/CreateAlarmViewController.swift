//
//  CreateAlarmViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 21/1/26.
//
import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore

class CreateAlarmViewController: UIViewController {
    
    @IBOutlet weak var radiusTextField: RoundedTextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    var initialCoordinate: CLLocationCoordinate2D?
    private let decimalDelegate = DecimalTextFieldDelegate(maxDecimals: 3)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard initialCoordinate != nil else {
            dismiss(animated: true)
            return
        }
        
        unitButton.configureDropdown(options: ["km", "m", "mi", "ft"]) { [weak self] selectedUnit in
            self?.unitButton.setTitle(selectedUnit, for: .normal)
            self?.maxRadiusLabel.text = RadiusHelper.radiusText(for: selectedUnit)
        }
        
        radiusTextField.delegate = decimalDelegate
        hideKeyboardWhenTappedAround()
    }
    
    @IBAction func discardView(_ sender: Any) {
        self.dismiss(animated: true)
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
        
        let minRadius = RadiusHelper.minRadius(for: unit)
        guard radiusInMeters >= 100 else {
            let message = String(format: "The minimum allowed radius for %@ is %.2f %@", unit, minRadius, unit)
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
    }
    
    @IBAction func addAlarm(_ sender: Any) {
        //TODO ADD LIMIT ON LENGTH
        guard let nameText = nameTextField.text else {
            showAlert(title: "Missing alarm's name", message: "Please select a name for your alarm")
            return
        }
        
        guard let radiusText = radiusTextField.text,
                let radius = Double(radiusText),
                radius > 0 else {
            showAlert(title: "Invalid radius", message: "Please enter a valid radius")
            return
        }
        
        let unit = unitButton.title(for: .normal) ?? "km"
        
        self.fetchActiveAlarmCount { activeCount in
            let canActivate = activeCount < 20

            self.saveAlarm(
                locationName: nameText,
                coordinate: self.initialCoordinate!,
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
                            Will play only when silent mode is off
                            """
                        ) {
                            self.dismiss(animated: true)
                        }
                    } else {
                        self.showAlert(
                            title: "Alarm created but inactive",
                            message: """
                            Apple enforces a limit of 20 active simultaneous alarms.
                            This alarm was saved but is inactive.
                            Disable another alarm to activate it.
                            """
                        ) {
                            self.dismiss(animated: true)
                        }
                    }
                }
            }
        }
        
    }
}

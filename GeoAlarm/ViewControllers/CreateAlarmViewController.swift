//
//  CreateAlarmViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 21/1/26.
//
import UIKit
import MapKit

class CreateAlarmViewController: UIViewController {
    
    @IBOutlet weak var radiusTextField: RoundedTextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    var initialCoordinate: CLLocationCoordinate2D?
    private let decimalDelegate = DecimalTextFieldDelegate(maxDecimals: 3)
    private let nameDelegate = MaxLengthTextFieldDelegate(maxLength: 50)
    
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
        nameTextField.delegate = nameDelegate
        hideKeyboardWhenTappedAround()
    }
    
    @IBAction func discardView(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func addAlarm(_ sender: Any) {
        guard let nameText = nameTextField.text else {
            showAlert(title: NSLocalizedString("missing_alarm", comment: "") , message: NSLocalizedString("no_name_warning", comment: "")
            )
            return
        }
        
        guard let radiusText = radiusTextField.text,
                let radius = Double(radiusText),
                radius > 0 else {
            showAlert(title: NSLocalizedString("invalid_radius",comment: ""),message: NSLocalizedString("enter_valid_radius",comment: "")
            )
            return
        }
        
        let unit = unitButton.title(for: .normal) ?? "km"
        
        FirestoreHelper.fetchActiveAlarmCount { activeCount in
            let canActivate = activeCount < 20

            PermissionsHelper.checkLocation(always: true) { granted in
                DispatchQueue.main.async {
                    let isActive = canActivate && granted
                    
                    FirestoreHelper.saveOrUpdateAlarm(
                        locationName: nameText,
                        coordinate: self.initialCoordinate!,
                        radius: radius,
                        unit: unit,
                        creationType: .map,
                        isActive: isActive
                    ) { result in
                        switch result {
                        case .failure(let error):
                            self.showAlert(title: "Error", message: error.localizedDescription)
                            
                        case .success:
                            if isActive {
                                self.showAlert(title: NSLocalizedString("alarm_success_title", comment: ""),
                                               message: NSLocalizedString("alarm_success_message", comment: "")) {
                                    self.dismiss(animated: true)
                                }
                            } else if !granted {
                                self.showAlert(title: NSLocalizedString("alarm_inactive_title", comment: ""),
                                               message: NSLocalizedString("alarm_inactive_permission_message", comment: "")) {
                                    self.dismiss(animated: true)
                                }
                            } else {
                                self.showAlert(title: NSLocalizedString("alarm_inactive_title", comment: ""),
                                               message: NSLocalizedString("alarm_inactive_message", comment: "")) {
                                    self.dismiss(animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}

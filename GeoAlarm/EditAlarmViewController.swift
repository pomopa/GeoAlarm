//
//  EditAlarmViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 5/1/26.
//
import UIKit

class EditAlarmViewController: UIViewController {

    var alarm: Alarm!

    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        populateUI()
    }

    private func populateUI() {
        nameSearchBar.text = alarm.locationName
        radiusTextField.text = "\(alarm.radius)"
    }

    @IBAction func saveTapped(_ sender: Any) {
        // Update Firestore
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
        // Firestore delete
        navigationController?.popViewController(animated: true)
    }
}

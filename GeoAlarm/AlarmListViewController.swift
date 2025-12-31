//
//  AlarmListViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class AlarmListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var alarms: [Alarm] = []
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadAlarms()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    private func loadAlarms() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }

        db.collection("users")
            .document(userId)
            .collection("alarms")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Firestore error:", error)
                    return
                }

                guard let documents = snapshot?.documents else { return }
                
                self?.alarms = documents.compactMap {
                    Alarm(id: $0.documentID, data: $0.data())
                }

                self?.tableView.reloadData()
            }
    }
    
    @IBAction func addAlarm(_ sender: Any) {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 2
        }
    }
    
    private func updateAlarmActiveState(
        alarmID: String,
        isActive: Bool
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        db.collection("users")
            .document(userId)
            .collection("alarms")
            .document(alarmID)
            .updateData([
                "isActive": isActive
            ]) { error in
                if let error = error {
                    print("Firestore update failed:", error)
                }
            }
    }

    
}

extension AlarmListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        alarms.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "AlarmTableViewCell",
            for: indexPath
        ) as? AlarmTableViewCell else {
            return UITableViewCell()
        }

        let alarm = alarms[indexPath.row]
        let distanceText = "\(alarm.radius) \(alarm.unit)"

        cell.configure(
            title: alarm.locationName,
            distance: distanceText,
            isEnabled: alarm.isActive
        )

        cell.onSwitchToggled = nil

        cell.onSwitchToggled = { [weak self] isOn in
            guard let self = self else { return }

            self.alarms[indexPath.row].isActive = isOn

            self.updateAlarmActiveState(
                alarmID: alarm.id,
                isActive: isOn
            )
        }

        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}


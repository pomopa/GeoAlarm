//
//  AlarmListViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation


class AlarmListViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var alarms: [Alarm] = []
    private let db = Firestore.firestore()
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadAlarms()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ProfileImageCache.shared.prefetchIfNeeded()
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
                self?.updateEmptyState()
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

    private func updateEmptyState() {
        if alarms.isEmpty {
            let container = UIView(frame: tableView.bounds)

            let label = UILabel()
            label.text = """
            No alarms yet ⏰
            """
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            let button = UIButton(type: .system)
            button.setTitle("Create Alarm", for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 17)
            button.addTarget(self, action: #selector(addAlarm(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -100),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24),

                button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16)
            ])

            tableView.backgroundView = container
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .none
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "alarmListToEditAlarm",
           let vc = segue.destination as? EditAlarmViewController,
           let alarm = sender as? Alarm {
            vc.alarm = alarm
        }
    }
}

extension AlarmListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        alarms.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alarm = alarms[indexPath.row]
        performSegue(withIdentifier: "alarmListToEditAlarm", sender: alarm)
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


//
//  AlarmListViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//


import UIKit
import FirebaseFirestore
import CoreLocation


class AlarmListViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var alarms: [Alarm] = []
    private var alarmsListener: ListenerRegistration?
    let locationManager = CLLocationManager()
    private var isTogglingAlarm = false
    private var isApplyingLocalChange = false
    
    private lazy var sizingCell: AlarmTableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmTableViewCell") as! AlarmTableViewCell
        return cell
    }()

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
    
    @IBAction func tutorialPressed(_ sender: Any) {
        let text = """
        CREATE ALARMS
        • Tap the + button, search icon, or a map location.
            
        REQUIREMENTS
        • Allow notifications and location access (Always).
        • Make sure Silent Mode is off.

        EDIT ALARMS
        • Tap an alarm in the list or on the map.
        """

        let attributedText = NSMutableAttributedString(string: text)

        let headers = ["CREATE ALARMS", "REQUIREMENTS", "EDIT ALARMS"]
        for header in headers {
            let range = (text as NSString).range(of: header)
            attributedText.addAttribute(
                .font,
                value: UIFont.preferredFont(forTextStyle: .headline),
                range: range
            )
        }

        let alert = UIAlertController(title: "App Tutorial", message: nil, preferredStyle: .alert)
        alert.setValue(attributedText, forKey: "attributedMessage")

        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }
    
    private func loadAlarms() {
        alarmsListener = FirestoreHelper.listenToAlarms(
            orderedByCreationDate: true
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                print("Firestore error:", error)
                return

            case .success(let alarms):
                self.alarms = alarms
                LocationManager.shared.syncActiveAlarms(alarms)
                if !self.isTogglingAlarm {
                    self.tableView.reloadData()
                }
                self.updateEmptyState()
            }
        }
    }
    
    private func activeAlarmCount(excluding alarmID: String? = nil) -> Int {
        alarms.filter {
            $0.isActive && $0.id != alarmID
        }.count
    }
    
    @IBAction func addAlarm(_ sender: Any) {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 2
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
        let radius = alarm.radius
        var radiusText = ""
        if floor(radius) == radius {
            radiusText = String(format: "%.0f", radius)
        } else {
            radiusText = String(radius)
        }
        let distanceText = "\(radiusText) \(alarm.unit)"

        cell.configure(
            title: alarm.locationName,
            distance: distanceText,
            isEnabled: alarm.isActive
        )

        cell.onSwitchToggled = nil

        cell.onSwitchToggled = { [weak self, weak cell] isOn in
            guard let self = self else { return }

            let alarm = self.alarms[indexPath.row]

            if self.isTogglingAlarm { return }
            self.isTogglingAlarm = true
            self.isApplyingLocalChange = true

            if isOn && self.activeAlarmCount(excluding: alarm.id) >= 20 {
                DispatchQueue.main.async {
                    cell?.setSwitchOn(false, animated: true)
                    self.showAlert(
                        title: "Maximum Active Alarms",
                        message: "You can only have up to 20 active alarms."
                    )
                    self.isTogglingAlarm = false
                    self.isApplyingLocalChange = false
                }
                return
            }

            self.alarms[indexPath.row].isActive = isOn
            
            if !NetworkMonitor.shared.isConnected {
                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Offline Mode",
                        message: "Changes will sync automatically when you're back online."
                    )
                }
            }

            DispatchQueue.global(qos: .userInitiated).async {
                if isOn {
                    LocationManager.shared.enableGeofence(for: alarm)
                } else {
                    LocationManager.shared.disableGeofence(id: alarm.id)
                }
            }

            FirestoreHelper.updateAlarmActiveState(
                alarmID: alarm.id,
                isActive: isOn
            ) { [weak self, weak cell] result in
                guard let self else { return }

                self.isTogglingAlarm = false
                self.isApplyingLocalChange = false

                if case .failure = result {
                    self.alarms[indexPath.row].isActive.toggle()
                    cell?.setSwitchOn(!isOn, animated: true)

                    self.showAlert(
                        title: "Offline",
                        message: "Changes will sync when you're back online."
                    )
                }
            }
        }


        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let alarm = alarms[indexPath.row]
        let radius = alarm.radius
        var radiusText = ""
        if floor(radius) == radius {
            radiusText = String(format: "%.0f", radius)
        } else {
            radiusText = String(radius)
        }

        sizingCell.configure(title: alarm.locationName,
                             distance: "\(radiusText) \(alarm.unit)",
                             isEnabled: alarm.isActive)
        sizingCell.layoutIfNeeded()

        let lines = sizingCell.titleLabel.numberOfTextLines

        return CGFloat(100 + ((lines - 1) * 20))
    }

}

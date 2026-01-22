import CoreLocation
import UIKit
import UserNotifications
import Foundation
import Alamofire

final class LocationManager: NSObject, CLLocationManagerDelegate {

    static let shared = LocationManager()
    private let manager = CLLocationManager()
    private var alarms: [String: Alarm] = [:]

    private override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermissions() {
        manager.requestAlwaysAuthorization()
    }
    
    func currentGeofenceIDs() -> Set<String> {
        Set(manager.monitoredRegions.map { $0.identifier })
    }

    func addGeofence(
        id: String,
        latitude: Double,
        longitude: Double,
        radius: Double
    ) {
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: id
        )

        region.notifyOnEntry = true
        region.notifyOnExit = false
        manager.startMonitoring(for: region)
    }
    
    private func triggerGeofenceNotification(
        for region: CLRegion,
        temperature: Double?
    ) {
        let content = UNMutableNotificationContent()
        let locationName = alarms[region.identifier]?.locationName ?? "your location"

        content.title = "⏰ Alarm Active in \(locationName)"

        if let temperature = temperature {
            content.body = """
            Current temperature: \(Int(temperature))°C
            """
        } else {
            content.body = "The alarm you set in \(locationName) has been activated"
        }

        content.sound = UNNotificationSound(
            named: UNNotificationSoundName("alarm.caf")
        )

        content.interruptionLevel = .timeSensitive
        content.badge = 1
        content.categoryIdentifier = "GEOFENCE_ALARM"

        let request = UNNotificationRequest(
            identifier: region.identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    
    private func fetchTemperature(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Double?) -> Void
    ) {
        guard
            let url = Bundle.main.url(forResource: "APIs", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any],
            let apiKey = plist["OPENWEATHER_API_KEY"] as? String
        else {
            fatalError("API key not found in APIs.plist")
        }
        
        let api_url = "https://api.openweathermap.org/data/2.5/weather"

        let parameters: Parameters = [
            "lat": latitude,
            "lon": longitude,
            "appid": apiKey,
            "units": "metric"
        ]

        AF.request(api_url, parameters: parameters).responseJSON { response in
            guard
                let json = response.value as? [String: Any],
                let main = json["main"] as? [String: Any],
                let temp = main["temp"] as? Double
            else {
                completion(nil)
                return
            }

            completion(temp)
        }
    }

    
    func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        guard state == .inside else { return }

        if let circularRegion = region as? CLCircularRegion {
            fetchTemperature(
                latitude: circularRegion.center.latitude,
                longitude: circularRegion.center.longitude
            ) { temperature in
                self.triggerGeofenceNotification(
                    for: region,
                    temperature: temperature
                )
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        if let circularRegion = region as? CLCircularRegion {
            fetchTemperature(
                latitude: circularRegion.center.latitude,
                longitude: circularRegion.center.longitude
            ) { temperature in
                self.triggerGeofenceNotification(
                    for: region,
                    temperature: temperature
                )
            }
        }
    }

    
    func syncActiveAlarms(_ alarms: [Alarm]) {
        removeAllGeofences()
        let activeAlarms = alarms.filter { $0.isActive }

        let registeredIDs = currentGeofenceIDs()

        for alarm in activeAlarms.prefix(20) {
            guard !registeredIDs.contains(alarm.id) else { continue }
            self.alarms[alarm.id] = alarm

            let radiusInMeters = RadiusHelper.calculateRadiusInMeters(
                unit: alarm.unit,
                value: alarm.radius
            )

            addGeofence(
                id: alarm.id,
                latitude: alarm.latitude,
                longitude: alarm.longitude,
                radius: radiusInMeters
            )
        }
    }

    func enableGeofence(for alarm: Alarm) {
        let registeredIDs = currentGeofenceIDs()
        guard !registeredIDs.contains(alarm.id) else { return }

        self.alarms[alarm.id] = alarm
        
        let radiusInMeters = RadiusHelper.calculateRadiusInMeters(
            unit: alarm.unit,
            value: alarm.radius
        )

        addGeofence(
            id: alarm.id,
            latitude: alarm.latitude,
            longitude: alarm.longitude,
            radius: radiusInMeters
        )
    }
    
    func disableGeofence(id: String) {
        let regionsToRemove = manager.monitoredRegions.filter {
            $0.identifier == id
        }
        
        for region in regionsToRemove {
            manager.stopMonitoring(for: region)
        }
        
        alarms.removeValue(forKey: id)
    }
    
    func removeAllGeofences() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        alarms.removeAll()
    }
}


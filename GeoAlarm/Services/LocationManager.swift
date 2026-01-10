import CoreLocation
import UserNotifications

final class LocationManager: NSObject, CLLocationManagerDelegate {

    static let shared = LocationManager()
    private let manager = CLLocationManager()

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
        //print(region.center)
        //print(region.radius)
        manager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager,
                         didEnterRegion region: CLRegion) {

        let content = UNMutableNotificationContent()
        content.title = "Geofence activat"
        content.body = "Has entrat a \(region.identifier)"
        //print(content.title)
        //print(content.body)
        let request = UNNotificationRequest(
            identifier: region.identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    func syncActiveAlarms(_ alarms: [Alarm]) {
        let activeAlarms = alarms.filter { $0.isActive }

        let registeredIDs = currentGeofenceIDs()

        for alarm in activeAlarms.prefix(20) {
            guard !registeredIDs.contains(alarm.id) else { continue }

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
    }
    
    func removeAllGeofences() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }
}

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
    func getFences () -> Set<CLRegion> {
        return manager.monitoredRegions
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
        print(region.center)
        print(region.radius)
        manager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager,
                         didEnterRegion region: CLRegion) {

        let content = UNMutableNotificationContent()
        content.title = "Geofence activat"
        content.body = "Has entrat a \(region.identifier)"
        print(content.title)
        print(content.body)
        print("ASDfasf")
        let request = UNNotificationRequest(
            identifier: region.identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
